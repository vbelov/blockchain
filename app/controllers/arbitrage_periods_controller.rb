class ArbitragePeriodsController < ApplicationController
  def index
    @periods = ArbitragePeriod.order(max_revenue: :desc).limit(100)
  end

  def show
    period = ArbitragePeriod.find(params[:id])
    points = period.arbitrage_points
    @revenue_chart = points.map { |point| [point.time, point.max_revenue] }
    @volume_chart = points.map { |point| [point.time, point.volume] }
    @profit_chart = points.select(&:max_revenue).select(&:volume)
                        .map { |point| [point.time, point.max_revenue / point.volume * 100.0] }
  end

  def best_point
    period = ArbitragePeriod.find(params[:id])
    point = period.arbitrage_points.max_by(&:max_revenue)
    redirect_to point
  end
end
