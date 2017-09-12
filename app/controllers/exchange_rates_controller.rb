class ExchangeRatesController < ApplicationController
  def index
    hash = Stocks::Yobit.new.current_exchange_rates('btc', 0.1)
    @rows = hash.map do |pair, rate|
      c1, c2 = pair.split('_')
      OpenStruct.new(currency1: c1.upcase, currency2: c2.upcase, rate: rate)
    end
  end
end
