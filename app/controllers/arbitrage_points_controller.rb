class ArbitragePointsController < ApplicationController
  def show
    period = ArbitragePeriod.find(params[:id])
    buy_stock_code = period.buy_stock_code
    sell_stock_code = period.sell_stock_code

    buy_glass = Glass.find_by(
        stock_code: buy_stock_code,
        target_code: period.target_code,
        base_code: period.base_code,
        time: Time.at(params[:at].to_i),
    )
    sell_glass = Glass.find_by(
        stock_code: sell_stock_code,
        target_code: period.target_code,
        base_code: period.base_code,
        time: Time.at(params[:at].to_i),
    )

    buy_stock = Stocks.const_get(buy_stock_code).new
    sell_stock = Stocks.const_get(sell_stock_code).new

    volumes = 500.times.map { |i| (i + 1).to_f * 0.01 }

    @arbitrage_chart = []
    @revenue_chart = []
    volumes.map do |volume|
      buy_rate = buy_stock.process_glass_fast(buy_glass, :buy, volume)
      sell_rate = sell_stock.process_glass_fast(sell_glass, :sell, volume)
      if sell_rate && buy_rate
        arbitrage = (sell_rate / buy_rate - 1)
        if arbitrage > 0
          @arbitrage_chart << [volume.round(2), arbitrage * 100]
          @revenue_chart << [volume.round(2), arbitrage * volume]
        end
      end
    end
  end
end
