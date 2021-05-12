class PaymentCharge < ApplicationRecord
  include AASM

  # validations
  validates_presence_of :amount
  validates_numericality_of :tax_percentage, greater_than_equal_to: 0, less_than_or_equal_to: 100

  # associations
  belongs_to :subscription_plan

  # scopes
  scope :due, -> { where(state: %w[pending ready_to_charge]) }

  aasm column: 'state', skip_validation_on_save: true do
    state :pending, initial: true
    state :processing
    state :ready_to_charge
    state :completed
    state :errored
    state :refunded

    event :charge do
      transitions from: :pending, to: :ready_to_charge
    end

    event :process do
      transitions from: :ready_to_charge, to: :processing
    end

    event :done do
      transitions from: :processing, to: :completed
    end

    event :fail do
      transitions from: %i[pending processing], to: :errored
    end

    event :refund do
      transitions from: %i[completed], to: :refunded
    end

  end

  def sync_data_with_stripe!(force = nil)
    return if company.in_initial_trial_period? && !force
    process!
    failed
    return if errored?
    customer = Stripe::Customer.retrieve(company.subscription.stripe_customer_id)

    if customer.balance >= 0
      # customer has debit balance in stripe, so charge the card
      stripe_charge = Stripe::Charge.create({ customer: customer.id }.merge(stripe_hash(total_amount)))
    else
      # customer has credit balance in stripe
      adjusted_amount = customer.balance + total_amount
      deductible_customer_balance = adjusted_amount.positive? ? customer.balance.abs : total_amount

      # deduct customer credit balance
      Stripe::Customer.create_balance_transaction(customer.id, stripe_hash(deductible_customer_balance))

      # charge is more than credit balance, so charge the card with remaining amount
      stripe_charge = Stripe::Charge.create({ customer: customer.id }.merge(stripe_hash(adjusted_amount))) if adjusted_amount.positive?
    end
    update_attributes(stripe_id: stripe_charge.id) if stripe_charge.present?
    done!
  rescue Stripe::StripeError, RuntimeError => e
    update_attributes(error: e.message)
    fail!
  end

  def failed
    return if amount != 0
    update_attributes(error: 'Amount is invalid')
    fail!
  end

  def total_amount
    ((amount + tax_amount) * quantity).ceil
  end

  def mark_ready_to_charge!
    return if company.in_initial_trial_period?
    charge!
  end

  def valid_charge?
    # When a company is in initial trial, charge state will be pending. We never charge a company during initial trial.
    ready_to_charge? || pending?
  end

  def payable_amount
    amount * quantity
  end

  def payable_amount_in_dollars
    amount / 100.00 * quantity
  end

  def stripe_hash(charge_amount)
    {
      amount: charge_amount,
      description: description || "#{subscription_plan.stripe_id}",
      currency: 'usd',
      metadata: {
        tax_percentage: tax_percentage,
        tax_amount: tax_amount * quantity
      }
    }
  end
end
