class ExchangeRate
  include Virtus.model

  attribute :pair, Pair
  attribute :buy_rate, Float
  attribute :sell_rate, Float
end
