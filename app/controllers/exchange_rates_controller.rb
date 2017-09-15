class ExchangeRatesController < ApplicationController
  helper_method :volume,
                :stock_names, :stock_name,
                :valid_pairs, :list_of_pairs, :pair

  def index
    @rows =
        stocks.flat_map do |stock|
          stock.current_exchange_rates(Currency.btc, volume, pairs: pair && [pair])
        end
    @messages = []
    @rows.group_by(&:pair).each do |pair, ers|
      ers.permutation(2).each do |er1, er2|
        if er1.buy_rate < er2.sell_rate
          er1.add_arbitrage_on(:buy)
          er2.add_arbitrage_on(:sell)
          arbitrage = ((er2.sell_rate / er1.buy_rate - 1) * 100.0).round(2)
          f = ->(number) { ActiveSupport::NumberHelper.number_to_rounded(number, precision: 8) }
          @messages << "#{pair.slashed_code}: Buy on #{er1.stock} for #{f.(er1.buy_rate)} and sell on #{er2.stock} for #{f.(er2.sell_rate)}. Arbitrage: #{arbitrage} %"
        end
      end
    end

    @rows.sort_by! { |er| er.pair.slashed_code }
  end

  private

  def stock_names
    %w(Yobit Poloniex)
  end

  def stock_name
    stock_names.find { |p| p == exchange_rates_params[:stock_name] }
  end

  def stocks
    @stocks ||=
        Array.wrap(stock_name || %w(Yobit Poloniex)).map do |name|
          Stocks.const_get(name).new
        end
  end

  def valid_pairs
    stocks.flat_map { |s| s.valid_pairs.map(&:slashed_code) }.uniq.sort
  end

  def list_of_pairs
    ['Все'] + valid_pairs
  end

  def pair
    _pair = exchange_rates_params[:pair]
    if _pair.blank?
      'ETH / BTC'
    elsif _pair == 'Все'
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
