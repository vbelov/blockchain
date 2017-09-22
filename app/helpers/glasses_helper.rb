module GlassesHelper
  def order_row_class(order)
    case order.used
      when :full; then 'success'
      when :partial; then 'warning'
      else nil
    end
  end

  def fr(rate)
    number_with_precision(rate, precision: 8)
  end

  def fv(volume)
    number_with_precision(volume, precision: 5)
  end

  def fs(share)
    "#{number_with_precision(share * 100.0, precision: 1)} %"
  end
end
