class Calculator
  include Virtus.model

  attribute :buy_stock_code, String
  # или
  attribute :buy_stock, Object

  attribute :sell_stock_code, String
  # или
  attribute :sell_stock, Object

  attribute :time, Time
  # или
  attribute :buy_glass, Glass
  attribute :sell_glass, Glass

  attribute :target_code, String
  attribute :base_code, String

  def initialize(*args)
    super

    self.buy_stock ||= Stocks.const_get(buy_stock_code).new
    self.sell_stock ||= Stocks.const_get(sell_stock_code).new

    self.buy_stock_code ||= buy_stock.stock_code
    self.sell_stock_code ||= sell_stock.stock_code

    self.buy_glass ||= Glass.find_by(
        stock_code: buy_stock_code,
        target_code: target_code,
        base_code: base_code,
        time: time,
    )
    self.sell_glass ||= Glass.find_by(
        stock_code: sell_stock_code,
        target_code: target_code,
        base_code: base_code,
        time: time,
    )
  end

  def fee_sell
    0.002
  end

  def fee_buy
    0.002
  end

  def withdrawal_fee_buy_target
    0.001
  end

  def withdrawal_fee_sell_base
    0.001
  end

  def min_volume
    0
  end

  def max_volume
    0.1
  end

  def get_proc
    @function ||= ->(volume) do
      buy_rate = buy_stock.process_glass_fast(buy_glass, :buy, volume)
      sell_rate = sell_stock.process_glass_fast(sell_glass, :sell, volume)
      if sell_rate && buy_rate
        target_revenue = (1 / (buy_rate * (1 - fee_buy)) - 1 / (sell_rate * (1 - fee_sell))) * volume - withdrawal_fee_buy_target
        if target_revenue > 0
          base_revenue = sell_stock.sell_target(sell_glass, target_revenue)
          rev = base_revenue - withdrawal_fee_sell_base
          rev > 0 ? rev : 0
        else
          0
        end
      else
        0
      end
    end
  end

  def get_reverse
    @reverse = ->(volume) do
      - get_proc.(volume)
    end
  end

  def calc_optimal
    @optimal ||= begin
      d = Minimization::Brent.new(min_volume, max_volume, get_reverse)
      # d.epsilon = 0.01
      d.iterate
      revenue = - d.f_minimum
      optimal_volume = d.x_minimum

      [optimal_volume, revenue]
    end
  end
end
