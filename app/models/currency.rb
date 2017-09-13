class Currency
  include Virtus.model
  include Comparable

  attribute :code, String

  class << self
    def find_by_code(code)
      @currencies = {}
      cur = @currencies[code]
      if !cur && allowed?(code)
        cur = @currencies[code] = Currency.new(code: code)
      end
      cur
    end

    def btc
      find_by_code 'btc'
    end

    def allowed?(code)
      code.in?(%w(btc eth bcc xrp ltc xem dash xmr iot etc omg gno neo qtum mtl))
      # %w(btc eth ltc)
    end
  end

  # noinspection RubyInstanceMethodNamingConvention
  def CODE
    code.upcase
  end

  def <=>(other)
    code <=> other.code
  end
end
