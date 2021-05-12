class BillingController < ApplicationController
  include ExceptionHandler
  load_and_authorize_resource :user
  expose_decorated :paid_customers, -> { Customer.paid.order('bill.marked_paid_at desc').page(params[:page]) }, decorator: UserDecorator, collection: true

  # response formats
  responders :flash
  respond_to :html, :js

  def show
    redirect_back fallback_location: main_path
  end

  def multiple_invoice
    if params[:invoice]
      multiple_invoices(params)
      redirect_to billing_index_path, notice: t('billing.success')
    else
      redirect_to billing_index_path, alert: t('billing.error')
    end
  end

  private

  def invoicing_params
    params.permit(:id, :internal_comment, :status)
  end

  def handle_404(_exception)
    redirect_back fallback_location: schedules_path 
  end
end
