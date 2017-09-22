class ArbitragePoint < ApplicationRecord
  belongs_to :arbitrage_period

  def rate_or_return
    max_revenue / volume
  end
end
