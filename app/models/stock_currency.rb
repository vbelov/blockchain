class StockCurrency < ApplicationRecord
  belongs_to :currency, foreign_key: 'app_currency_code'

  def stock
    @stock ||= Stock.find_by_code(stock_code)
  end
end
