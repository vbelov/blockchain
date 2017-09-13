class Pair
  include Virtus.model

  attribute :target_currency, Currency
  attribute :base_currency, Currency

  def target_code
    target_currency.code
  end

  def base_code
    base_currency.code
  end

  def slashed_code
    "#{target_currency.CODE} / #{base_currency.CODE}"
  end

  def underscored_code
    "#{target_currency.code}_#{base_currency.code}"
  end
end
