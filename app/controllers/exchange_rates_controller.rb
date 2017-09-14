class ExchangeRatesController < ApplicationController
  helper_method :volume,
                :stock_names, :stock_name,
                :valid_pairs, :list_of_pairs, :pair

  def index
    @rows =
        stocks.flat_map do |stock|
          stock.current_exchange_rates(Currency.btc, volume, pairs: pair && [pair])
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
