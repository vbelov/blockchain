class CommandsController < ApplicationController
  def index
  end

  def refresh_glasses
    stock_code = params[:stock_code]
    Stocks.const_get(stock_code).new.refresh_glasses
    flash.notice = "#{stock_code}: данные успешно обновлены"
    redirect_to commands_path
  end
end
