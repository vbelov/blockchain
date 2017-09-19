class Pair
  include Virtus.model
  include Comparable

  attribute :target_currency, Currency
  attribute :base_currency, Currency

  def target_code
    target_currency.code
  end

  # noinspection RubyInstanceMethodNamingConvention
  def target_CODE
    target_currency.CODE
  end

  def base_code
    base_currency.code
  end

  # noinspection RubyInstanceMethodNamingConvention
  def base_CODE
    base_currency.CODE
  end

  def slashed_code
    "#{target_currency.CODE} / #{base_currency.CODE}"
  end

  def underscored_code
    "#{target_currency.code}_#{base_currency.code}"
  end

  def <=>(other)
    underscored_code <=> other.underscored_code
  end

  def ==(other)
    other.kind_of?(self.class) && underscored_code == other.underscored_code
  end

  def eql?(other)
    other.instance_of?(self.class) && underscored_code == other.underscored_code
  end

  def hash
    underscored_code.to_sym.object_id
  end

  class << self
    def find_by_code(code)
      c1, c2 = code.split(' / ')
      Pair.new(
          target_currency: Currency.find_by_code(c1),
          base_currency: Currency.find_by_code(c2),
      )
    end

    def active
      Stock.all.flat_map { |code| Stocks.const_get(code).new.valid_pairs }.uniq
    end
  end
end
