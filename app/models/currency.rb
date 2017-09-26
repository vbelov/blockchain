class Currency
  include Virtus.model
  include Comparable

  attribute :code, String

  class << self
    def find_by_code(code)
      code = code.downcase
      code = 'btc' if code == 'xbt'
      @currencies = {}
      cur = @currencies[code]
      if !cur && allowed?(code)
        cur = @currencies[code] = Currency.new(code: code)
      end
      cur
    end

    def find_by_code!(code)
      find_by_code(code) || raise("Failed to find currency #{code}")
    end

    def btc
      find_by_code 'btc'
    end

    def allowed?(code)
      code.in?(%w(bcc bch btc cny dash etc eth eur gno iot ltc mtl neo omg qtum usd usdt xem xmr xrp zec lsk waves strat doge steem))
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

  def btc?
    code == 'btc'
  end
end
