class CreateArbitragePeriods
  def run
    ArbitragePeriod.delete_all
    ArbitragePoint.delete_all

    ActiveRecord::Base.logger.silence do
      pairs = Pair.active
      # pairs = [Pair.find_by_code('XEM / BTC')]
      pairs.each { |pair| process_pair(pair) }
    end
    true
  end

  def process_pair(pair)
    puts "processing pair #{pair.slashed_code}"
    volume = 0

    points_by_stock = {}

    stocks = Stock.all
    # stocks = %w(Yobit Poloniex)
    stocks.each do |stock|
      stock_code = stock.code
      glasses = Glass.where(
          stock_code: stock_code,
          target_code: pair.target_code,
          base_code: pair.base_code,
      ).order(:time).to_a

      if glasses.any?
        stock_points = begin
          %i(sell buy).map do |action|
            points = glasses.map do |glass|
              rate = stock.process_glass_fast(glass, action, volume)
              [glass.time, rate]
            end
            [action, points]
          end.to_h
        end

        points_by_stock[stock_code] = stock_points
      end
    end
    active_stocks = points_by_stock.keys

    active_stocks.combination(2).each do |pos|
      [pos, pos.reverse].each do |pair_of_stocks|
        stock1 = pair_of_stocks[0]
        stock2 = pair_of_stocks[1]
        buy_points = points_by_stock[stock1][:buy]
        sell_points = points_by_stock[stock2][:sell]

        sell_points_by_time = sell_points.index_by(&:first)

        points = buy_points.map do |point|
          time = point[0]
          sell_point = sell_points_by_time[time]
          if sell_point
            buy_price = point[1]
            sell_price = sell_point[1]
            [time, (sell_price / buy_price - 1) * 100.0]
          end
        end.compact

        process_unit(stock1, stock2, pair, points)
      end
    end
  end

  def process_unit(buy_stock, sell_stock, pair, points)
    puts "processing #{buy_stock} / #{sell_stock}, #{pair.slashed_code}"

    period_started_at = nil
    period_points = []
    periods = []

    points.each do |point|
      time = point[0]
      arbitrage = point[1]

      if arbitrage > 0
        period_points << point
        period_started_at ||= time
      else
        if period_started_at
          finished_at = period_points.last[0]
          duration = (finished_at - period_started_at).to_i

          periods << ArbitragePeriod.new(
              buy_stock_code: buy_stock,
              sell_stock_code: sell_stock,
              target_code: pair.target_code,
              base_code: pair.base_code,
              started_at: period_started_at,
              finished_at: finished_at,
              duration: duration,
          )

          period_points.clear
          period_started_at = nil
        end
      end
    end

    periods.each_with_index do |period, idx|
      puts "processing arbitrage period #{idx} / #{periods.count}" if idx % 10 == 0
      process_arbitrage_period(period)
    end
  end

  def process_arbitrage_period(period)
    buy_stock_code = period.buy_stock_code
    sell_stock_code = period.sell_stock_code

    buy_stock = Stock.find_by_code(buy_stock_code)
    sell_stock = Stock.find_by_code(sell_stock_code)

    time_range = (period.started_at..period.finished_at)
    buy_glasses = Glass.where(
        stock_code: buy_stock_code,
        target_code: period.target_code,
        base_code: period.base_code,
        time: time_range,
    ).to_a.index_by(&:time)
    sell_glasses = Glass.where(
        stock_code: sell_stock_code,
        target_code: period.target_code,
        base_code: period.base_code,
        time: time_range,
    ).to_a.index_by(&:time)

    points_with_revenue = []

    time = period.started_at
    while time <= period.finished_at
      buy_glass = buy_glasses[time]
      sell_glass = sell_glasses[time]
      if buy_glass && sell_glass
        calculator = Calculator.new(
            buy_stock: buy_stock,
            sell_stock: sell_stock,
            target_code: period.target_code,
            base_code: period.base_code,
            buy_glass: buy_glass,
            sell_glass: sell_glass,
        )
        volume_for_max_revenue, max_revenue = calculator.calc_optimal

        if max_revenue > 0
          points_with_revenue << {
              time: time,
              max_revenue: max_revenue,
              volume: volume_for_max_revenue,
          }
        end
      end

      time += 1.minute
    end

    if points_with_revenue.any?
      points_with_revenue.each do |point_attributes|
        period.arbitrage_points.build(point_attributes)
      end

      point = period.arbitrage_points.max_by(&:max_revenue)
      max_revenue = point.max_revenue
      volume = point.volume
      arbitrage = volume > 0 ? max_revenue / volume : 0

      started_at  = period.arbitrage_points.map(&:time).min
      finished_at = period.arbitrage_points.map(&:time).max
      duration    = (finished_at - started_at).to_i

      period.update!(
          max_revenue: max_revenue,
          volume: volume,
          max_arbitrage: arbitrage,
          started_at: started_at,
          finished_at: finished_at,
          duration: duration,
      )
    end
  end
end
