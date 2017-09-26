class Stock
  include Virtus.model
  include Stocks::Base
  include Stocks::CrossPairs

  attribute :code, String


  class << self
    def all_codes
      @all_codes ||= %w(Yobit Poloniex Exmo Livecoin C2cx Bittrex Kraken Cexio Bitfinex Liqui Bter).sort
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

  def visible_pairs
    @visible_pairs ||= StockPair.find_all_by(stock_code: code, visible: true)
  end

  def cross_pairs
    @cross_pairs ||= StockPair.find_all_by(stock_code: code, cross: true)
  end

  def get_stock_pair(pair_or_code)
    pair = pair_or_code.is_a?(Pair) ? pair_or_code : Pair.find_by_code(pair_or_code)
    StockPair.find_all_by(stock_code: code, pair: pair).first
  end
end
