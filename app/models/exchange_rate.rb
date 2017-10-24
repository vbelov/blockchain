class ExchangeRate
  include Virtus.model

  attribute :stock, String
  attribute :pair, Pair
  attribute :buy_rate, Float
  attribute :sell_rate, Float
  attribute :arbitrage_on, Array[Symbol]
  attribute :outdated, Boolean

  def add_arbitrage_on(action)
    self.arbitrage_on ||= []
    self.arbitrage_on << action
    self.arbitrage_on.uniq!
  end
end
