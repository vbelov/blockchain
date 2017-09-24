class ExchangeRatesController < ApplicationController
  helper_method :volume,
                :stock,
                :valid_pairs, :list_of_pairs, :selected_pair

  def index
    rates = stocks.flat_map do |stock|
      stock.current_exchange_rates(Currency.btc, volume, pairs: selected_pair && [selected_pair])
    end
    @messages = []
    @rates_by_pair = rates.group_by(&:pair).to_a.sort_by { |pair, ers| pair.slashed_code }.to_h
    @rates_by_pair.each do |pair, ers|
      ers.permutation(2).each do |er1, er2|
        if er1.buy_rate < er2.sell_rate
          arbitrage = ((er2.sell_rate / er1.buy_rate - 1) * 100.0).round(2)
          if arbitrage > 1
            er1.add_arbitrage_on(:buy)
            er2.add_arbitrage_on(:sell)
            f = ->(number) { ActiveSupport::NumberHelper.number_to_rounded(number, precision: 8) }
            @messages << "#{pair.slashed_code}: Buy on #{er1.stock} for #{f.(er1.buy_rate)} and sell on #{er2.stock} for #{f.(er2.sell_rate)}. Arbitrage: #{arbitrage} %"
          end
        end
      end
    end
  end

  private

  def stock
    Stock.find_by_code(exchange_rates_params[:stock_name])
  end

  def stocks
    @stocks ||= Array.wrap(stock || Stock.all)
  end

  def valid_pairs
    stocks.flat_map { |s| s.visible_pairs.map(&:slashed_code) }.uniq.sort
  end

  def list_of_pairs
    ['Все'] + valid_pairs
  end

  def selected_pair
    _pair = exchange_rates_params[:pair]
    if _pair.blank? || _pair == 'Все'
      nil
    else
      valid_pairs.find { |p| p == _pair }
    end
  end

  def volume
    (exchange_rates_params[:volume].presence || 0.1).to_f
  end

  def exchange_rates_params
    params[:exchange_rates].presence || {}
  end
end
