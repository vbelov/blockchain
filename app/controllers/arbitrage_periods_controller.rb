class ArbitragePeriodsController < ApplicationController
  helper_method :best_point

  def index
    @periods = ArbitragePeriod.order(max_revenue: :desc).limit(100)
  end

  def show
    point_by_time = period.arbitrage_points.index_by(&:time)
    time = period.started_at
    @charts = %i(revenue volume profit).map { |c| [c, []] }.to_h
    while time <= period.finished_at

      point = point_by_time[time]

      revenue = point&.max_revenue || 0
      volume = point&.volume || 0
      profit = volume > 0 ? (revenue / volume) * 100.0 : 0

      @charts[:revenue] << [time, revenue]
      @charts[:volume]  << [time, volume]
      @charts[:profit]  << [time, profit]

      time += 1.minute
    end
  end

  private

  def period
    @period ||= ArbitragePeriod.find(params[:id])
  end

  def best_point
    @best_point ||= period.arbitrage_points.max_by(&:max_revenue)
  end
end
