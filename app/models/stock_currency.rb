class StockCurrency < ApplicationRecord
  belongs_to :currency, foreign_key: 'app_currency_code'

  delegate :CODE, to: :currency

  def stock
    @stock ||= Stock.find_by_code(stock_code)
  end

  def withdrawal_fee_str
    if withdrawal_fee
      "#{withdrawal_fee} #{self.CODE}"
    end
  end
end
