module Graphs
  class ArbitrageController < ApplicationController
    include ActiveSupport::Benchmarkable
    helper_method :valid_pairs, :pair, :volume, :charts

    def show
    end

    private

    def charts
      @charts ||=
          begin
            active_stocks = []
            pair_of_actions = %i(sell buy)
            points_by_stock = {}

            Stock.all.each do |stock|
              stock_code = stock.code
              time = 24.hours.ago
              glasses = Glass.where(
                  stock_code: stock_code,
                  target_code: target_currency,
                  base_code: base_currency,
              ).where('time > ?', time).order(:time).to_a

              if glasses.any?
                active_stocks << stock_code

                stock_points = benchmark "processing glasses for stock #{stock_code}" do
                  pair_of_actions.map do |action|
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

            arr = []

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

                title = "Покупка на #{stock1}, продажа на #{stock2}"
                arr << {title: title, chart_data: points}
              end
            end

            arr
          end
    end

    def vector
      Vector.my_find(target_currency, base_currency, action)
    end

    def target_currency
      pair.split(' / ')[0].downcase
    end

    def base_currency
      pair.split(' / ')[1].downcase
    end

    def valid_pairs
      Stock.all
          .flat_map(&:valid_pairs)
          .group_by(&:itself)
          .select { |p, pairs| pairs.count > 1 }
          .map(&:first)
          .map(&:slashed_code)
    end

    def pair
      find = ->(code) { valid_pairs.find { |p| p == code } }
      find.(glass_params[:pair]) || find.('ETH / BTC') || valid_pairs.first
    end

    def volume
      (glass_params[:volume].presence || 0.1).to_f
    end

    def glass_params
      params[:glass].presence || {}
    end
  end
end
