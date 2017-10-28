class StocksController < ApplicationController
  helper_method :stock

  def index
  end

  def show
  end

  def edit
  end

  def update
    stock.update!(stock_params)
    redirect_to stock
  end

  private

  def stock
    @stock ||= Stock.find_by_code(params[:id])
  end

  def stock_params
    params.require(:stock).permit(:buy_fee, :sell_fee)
  end
end
