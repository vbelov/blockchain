class ArbitragePeriod < ApplicationRecord
  has_many :arbitrage_points

  def stock_pair_code
    "#{buy_stock_code} / #{sell_stock_code}"
  end

  def pair_code
    "#{target_code.upcase} / #{base_code.upcase}"
  end
end
