class ArbitragePeriod < ApplicationRecord
  has_many :arbitrage_points
  belongs_to :buy_stock, class_name: 'Stock', foreign_key: 'buy_stock_code'
  belongs_to :sell_stock, class_name: 'Stock', foreign_key: 'sell_stock_code'

  def stock_pair_code
    "#{buy_stock_code} / #{sell_stock_code}"
  end

  def pair_code
    "#{target_code.upcase} / #{base_code.upcase}"
  end
end
