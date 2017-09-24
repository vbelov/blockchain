class Stock
  include Virtus.model
  include Stocks::Base

  attribute :code, String


  class << self
    def all_codes
      %w(Yobit Poloniex Exmo Livecoin)
    end

    def all
      @all ||= all_codes.map do |code|
        stock = Stock.new(
            code: code,
        )
        _module = Stocks.const_get(code)
        stock.extend(_module)
        stock
      end
    end

    def find_by_code(code)
      all.find { |s| s.code == code }
    end
  end

  all_codes.each do |code|
    [code, code.underscore].each do |_code|
      define_singleton_method(_code) do
        find_by_code(code)
      end
    end
  end

  def active_pairs
    @active_pairs ||= StockPair.find_all_by(stock_code: code, active: true)
  end

  def get_stock_pair(pair)
    active_pairs.find { |stock_pair| stock_pair.pair == pair }
  end
end
