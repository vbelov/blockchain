class StockCurrenciesController < ApplicationController
  helper_method :stock_currency, :stock

  def edit
  end

  def update
    stock_currency.update!(stock_currency_params)
    redirect_to stock
  end

  private

  def stock_currency
    @stock_currency ||= StockCurrency.find(params[:id])
  end

  def stock
    stock_currency.stock
  end

  def stock_currency_params
    params.require(:stock_currency).permit(:withdrawal_fee)
  end
end
