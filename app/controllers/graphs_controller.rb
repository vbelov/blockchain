class GraphsController < ApplicationController
  helper_method :valid_pairs, :pair, :volume, :charts

  def index
  end

  private

  def charts
    @charts ||=
        begin
          time = [1.day.ago, Time.parse('2017-09-15 17:00:00 +0300')].max
          glasses = Glass.where(
              stock_code: stock_names,
              target_code: target_currency,
              base_code: base_currency,
          ).where('created_at > ?', time).order(:created_at).to_a

          arr = []

          stock_names.permutation(2).each do |pair_of_stocks|
            pair_of_actions = %i(sell buy)
            buy_points, sell_points = 2.times.map do |idx|
              stock_code = pair_of_stocks[idx]
              action = pair_of_actions[idx]
              stock = Stocks.const_get(stock_code).new
              gg = glasses.select { |g| g.stock_code == stock_code }
              gg.map do |glass|
                res = stock.process_glass(glass, action, volume)
                [glass.created_at, res.effective_rate]
              end
            end

            sell_iterator = sell_points.to_enum
            prev_sell = sell_iterator.next
            prev_sell_at = prev_sell[0]
            next_sell = sell_iterator.peek
            next_sell_at = next_sell[0]

            points = buy_points.map do |point|
              created_at = point[0]
              while next_sell_at < created_at
                begin
                  prev_sell, next_sell = next_sell, sell_iterator.next
                  prev_sell_at, next_sell_at = next_sell_at, next_sell[0]
                rescue StopIteration
                  prev_sell = next_sell
                  prev_sell_at = next_sell_at
                  break
                end
              end
              if next_sell_at >= created_at
                take_next = (created_at - prev_sell_at) > (next_sell_at - created_at)
                # dt = [(created_at - prev_sell_at).abs, (next_sell_at - created_at).abs].min
                # puts "dt: #{dt}"
                sell = take_next ? next_sell : prev_sell
              else
                sell = prev_sell
              end
              buy_price = point[1]
              sell_price = sell[1]
              [created_at, (buy_price / sell_price - 1) * 100.0]
            end
            title = "Покупка на #{pair_of_stocks[1]}, продажа на #{pair_of_stocks[0]}"
            arr << {title: title, chart_data: points}
          end

          arr
        end
  end

  # def charts
  #   @charts ||=
  #       begin
  #         glasses = Glass.where(
  #             stock_code: stock_names,
  #             target_code: target_currency,
  #             base_code: base_currency,
  #         ).order(:created_at).to_a
  #
  #         arr = []
  #
  #         stock_names.combination(2).each do |pair_of_stocks|
  #           %i(buy sell).permutation(2).each do |pair_of_actions|
  #             arr << 2.times.map do |idx|
  #               stock_code = pair_of_stocks[idx]
  #               action = pair_of_actions[idx]
  #               stock = Stocks.const_get(stock_code).new
  #               gg = glasses.select { |g| g.stock_code == stock_code }
  #               chart_data = gg.map do |glass|
  #                 res = stock.aaa(glass, action, volume)
  #                 [glass.created_at, res.effective_rate]
  #               end
  #
  #               {name: "#{stock_code} #{action}", data: chart_data}
  #             end
  #           end
  #         end
  #
  #         arr
  #       end
  # end

  # def min(chart)
  #   chart.flat_map { |h| h[:data].map(&:last) }.min * 0.98
  # end
  #
  # def max(chart)
  #   chart.flat_map { |h| h[:data].map(&:last) }.max * 1.02
  # end

  def stock_names
    %w(Yobit Poloniex)
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
    stock_names
        .flat_map { |code| Stocks.const_get(code).new.valid_pairs.map { |p| [p, code] } }
        .group_by(&:first)
        .select { |p, stocks| stocks.count > 1 }
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
