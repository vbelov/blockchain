module Graphs
  class RatesController < ApplicationController
    helper_method :pair_codes, :pair,
                  :volume,
                  :group_by_options, :group_by,
                  :chart_groups, :min, :max

    def index
    end

    private

    def chart_groups
      return @chart_groups if @chart_groups

      @chart_groups = {}

      Stock.all.each do |stock_code|
        stock = Stocks.const_get(stock_code).new

        glasses = Glass.where(
            stock_code: stock_code,
            target_code: target_currency,
            base_code: base_currency,
        ).where('time > ?', 24.hours.ago).order(:time).to_a

        if glasses.any?
          %i(buy sell).each do |action|
            chart_data = glasses.map do |glass|
              rate = stock.process_glass_fast(glass, action, volume)
              [glass.time, rate]
            end

            add_chart(stock_code, action, chart_data)
          end
        end
      end

      @chart_groups
    end

    def min(group_name)
      chart_groups[group_name].flat_map { |h| h[:data].map(&:last) }.min * 0.999
    end

    def max(group_name)
      chart_groups[group_name].flat_map { |h| h[:data].map(&:last) }.max * 1.001
    end

    def add_chart(stock, action, data)
      action_name = action == :buy ? 'Покупка' : 'Продажа'

      if group_by == 'operation'
        @chart_groups[action_name] ||= []
        @chart_groups[action_name] << {name: stock, data: data}
      else
        @chart_groups[stock] ||= []
        @chart_groups[stock] << {name: action_name, data: data}
      end
    end

    def pair_codes
      Pair.active.map(&:slashed_code).sort
    end

    def pair
      find = ->(code) { pair_codes.find { |p| p == code } }
      find.(params[:pair]) || find.('ETH / BTC') || pair_codes.first
    end

    def target_currency
      pair.split(' / ')[0].downcase
    end

    def base_currency
      pair.split(' / ')[1].downcase
    end

    def volume
      (params[:volume].presence || 0.1).to_f
    end

    def group_by_options
      {
          stock: 'биржа',
          operation: 'операция',
      }.stringify_keys
    end

    def group_by
      group_by_options.keys.find { |k| k == params[:group_by] } || 'operation'
    end
  end
end
