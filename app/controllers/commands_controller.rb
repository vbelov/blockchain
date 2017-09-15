class CommandsController < ApplicationController
  helper_method :stocks

  def index
  end

  def refresh_glasses
    stock_code = params[:stock_code]
    Stocks.const_get(stock_code).new.refresh_glasses
    flash.notice = "#{stock_code}: данные успешно обновлены"
    redirect_to commands_path
  end

  private

  def stocks
    %w(Yobit Poloniex).map { |c| Stocks.const_get(c).new }
  end
end
