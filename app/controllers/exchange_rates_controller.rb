class ExchangeRatesController < ApplicationController
  helper_method :volume,
                :stock,
                :list_of_pairs, :selected_pair

  def index
    rates = current_exchange_rates
    @messages = []
    @rates_by_pair = rates.group_by(&:pair).to_a.sort_by { |pair, ers| pair.slashed_code }.to_h
    @rates_by_pair.each do |pair, ers|
      ers.permutation(2).each do |er1, er2|
        if er1.buy_rate && er2.sell_rate && er1.buy_rate < er2.sell_rate
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

  def current_exchange_rates
    base_currency = Currency.btc
    base_amount = volume

    now = Time.zone.now
    time = now.at_beginning_of_minute
    time = time - 1.minute if now.sec < 30
    glasses = Glass.where(time: time).to_a

    stocks.flat_map do |stock|
      stock_pairs = selected_pair ?
          Array.wrap(selected_pair).map { |p| stock.get_stock_pair(p) }.compact.select(&:visible) :
          stock.visible_stock_pairs

      stock_pairs.map do |stock_pair|
        pair = stock_pair.pair
        er = ExchangeRate.new(stock: stock.code, pair: pair)

        if pair.base_currency == base_currency
          glass = glasses.find do |g|
            g.stock_code == stock.code && g.target_code == pair.target_code && g.base_code == pair.base_code
          end

          if glass
            [:buy, :sell].each do |action|
              rate = stock.process_glass_fast(glass, action, base_amount)
              er.send("#{action}_rate=", rate) if rate
            end
          else
            er.outdated = true
          end
        end

        er
      end
    end
  end

  def stock
    Stock.find_by_code(params[:stock_name]) if params[:stock_name].present?
  end

  def stocks
    @stocks ||= Array.wrap(stock || Stock.all)
  end

  def pair_codes
    stocks.flat_map { |s| s.visible_pairs.map(&:slashed_code) }.uniq.sort
  end

  def list_of_pairs
    ['Все'] + pair_codes
  end

  def selected_pair
    _pair = params[:pair]
    if _pair.blank? || _pair == 'Все'
      nil
    else
      pair_codes.find { |p| p == _pair }
    end
  end

  def volume
    (params[:volume].presence || 0.1).to_f
  end
end
