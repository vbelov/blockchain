class Stock
  include Virtus.model

  attribute :code, String


  class << self
    # TODO rename to all_codes
    def all
      %w(Yobit Poloniex Exmo Livecoin)
    end

    def _all
      @all ||= all.map do |code|
        Stock.new(
            code: code,
        )
      end
    end

    def find_by_code(code)
      _all.find { |s| s.code == code }
    end
  end

  all.each do |code|
    [code, code.underscore].each do |_code|
      define_singleton_method(_code) do
        find_by_code(code)
      end
    end
  end

  def active_pairs
    @active_pairs ||= StockPair.find_all_by(stock_code: code, active: true)
  end

  def api
    @api ||= Stocks.const_get(code).new
  end

  def get_stock_pair(pair)
    active_pairs.find { |stock_pair| stock_pair.pair == pair }
  end
end
