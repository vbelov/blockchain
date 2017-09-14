class ExchangeRate
  include Virtus.model

  attribute :stock, String
  attribute :pair, Pair
  attribute :buy_rate, Float
  attribute :sell_rate, Float
end
