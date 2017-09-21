class ArbitragePointsController < ApplicationController
  helper_method :ef

  def show
    point = ArbitragePoint.find(params[:id])
    args = point.arbitrage_period.attributes
               .slice(*%w(buy_stock_code sell_stock_code base_code target_code))
               .merge(time: point.time)
    calculator = Calculator.new(args)

    @arbitrage_chart = []
    @revenue_chart = []

    step = 0.01
    max = calculator.max_volume
    cnt = (max / step).to_i
    volumes = cnt.times.map { |i| (i + 1).to_f * step }
    volumes.map do |volume|
      revenue = calculator.get_proc.(volume)
      if revenue > 0
        arbitrage = revenue / volume
        @arbitrage_chart << [volume.round(2), arbitrage * 100]
        @revenue_chart << [volume.round(2), revenue]
      end
    end

    @optimal_volume, @optimal_revenue = calculator.calc_optimal
    @instruction_data = InstructionHelper.new(calculator).prepare(@optimal_volume)
  end

  private

  def ef(val)
    if val > 1
      val.round(2)
    else
      cnt = Math.log10(val.abs).abs.to_i
      if cnt
        val.round(cnt + 4)
      else
        val
      end
    end
  end
end
