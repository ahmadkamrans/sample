class SlotDecorator < ApplicationDecorator
  delegate_all

  def status_class
    color = golfer_status_text_class

    icon = case aasm_payment_state&.to_sym
    when :unpaid then 'bi-record-circle-fill'
    when :processing then 'bi-record-circle-fill'
    when :paid then 'bi-circle-fill'
    when :payment_failed then 'bi-record-circle-fill'
    else 'bi-circle'
    end

    [icon, color].compact
  end

  def golfer_status_text_class
    case aasm_golfer_state&.to_sym
      when :reserved then 'bg-dark'
      when :checked_in then 'bg-success'
      when :no_show then 'bg-danger'
      when :cancelled then 'bg-danger'
      else :dark
    end
  end

  def payment_status_text_class
    case aasm_payment_state&.to_sym
    when :unpaid then 'text-dark'
    when :processing then 'text-info'
    when :paid then 'text-success'
    when :payment_failed then 'text-danger'
    else 'text-dark'
    end
  end

  def deleting?
    _destroy.true?
  end

  def editing?
    !persisted? || _editing.true?
  end
end
