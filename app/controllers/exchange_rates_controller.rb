class ExchangeRatesController < ApplicationController
  helper_method :volume

  def index
    @rows = Stocks::Yobit.new.current_exchange_rates('btc', volume)
  end

  private

  def volume
    (exchange_rates_params[:volume].presence || 0.1).to_f
  end

  def exchange_rates_params
    params[:exchange_rates].presence || {}
  end
end
