class Vector
  include Virtus.model

  attribute :pair, Pair
  attribute :action, Symbol

  delegate :target_currency, :base_currency,
           :target_code, :base_code,
           to: :pair

  def sell?
    action == :sell
  end

  def self.my_find(target_code, base_code, action)
    pair = Pair.new(
        target_currency: Currency.find_by_code(target_code),
        base_currency: Currency.find_by_code(base_code),
    )
    Vector.new(pair: pair, action: action)
  end
end
