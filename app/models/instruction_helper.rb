class InstructionHelper
  attr_reader :calculator

  METHODS = %i(sell_stock_code buy_stock_code target_code base_code fee_sell fee_buy withdrawal_fee_sell_base withdrawal_fee_buy_target)

  delegate *METHODS, to: :calculator
  delegate :buy_stock, :sell_stock, :buy_glass, :sell_glass, to: :calculator


  def initialize(calculator)
    @calculator = calculator
  end

  def prepare(volume)
    buy_rate = buy_stock.process_glass_fast(buy_glass, :buy, volume)
    sell_rate = sell_stock.process_glass_fast(sell_glass, :sell, volume)

    q_y_b = volume
    q_x_a = q_y_b / (sell_rate * (1 - fee_sell))
    q_x_b = q_y_b / (buy_rate * (1 - fee_buy))
    q_y_a = q_y_b
    q_y_b_star = q_y_a - withdrawal_fee_sell_base
    q_x_a_star = q_x_b - withdrawal_fee_buy_target
    base_delta = q_y_b_star - q_y_b
    target_delta = q_x_a_star - q_x_a
    target_delta_in_base = sell_stock.sell_target(sell_glass, target_delta)
    total_base_delta = target_delta_in_base + base_delta

    hash = binding.local_variables.map do |key|
      [key, binding.local_variable_get(key)]
    end.to_h

    METHODS.each do |m|
      hash[m] = calculator.send(m)
    end

    hash
  end
end
