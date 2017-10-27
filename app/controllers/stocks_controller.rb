class StocksController < ApplicationController
  def index
  end

  def show
    @stock = Stock.find_by_code(params[:id])
  end
end
