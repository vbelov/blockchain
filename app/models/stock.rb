class Stock
  include Virtus.model
  include Stocks::Base
  include Stocks::CrossPairs

  attribute :code, String


  class << self
    def all_codes
      @all_codes ||= %w(Yobit Poloniex Exmo Livecoin Bittrex Kraken Cexio Bitfinex Liqui Bter Bitstamp).sort
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

  def stock_pairs
    @stock_pairs ||= StockPair.find_all_by(stock_code: code)
  end

  def downloadable_stock_pairs
    @downloadable_stock_pairs ||= StockPair.find_all_by(stock_code: code, active: true)
  end

  def downloadable_pairs
    @downloadable_pairs ||= downloadable_stock_pairs.map(&:pair)
  end

  def visible_stock_pairs
    @visible_stock_pairs ||= StockPair.find_all_by(stock_code: code, visible: true)
  end

  def visible_pairs
    @visible_pairs ||= visible_stock_pairs.map(&:pair)
  end

  def cross_pairs
    @cross_pairs ||= StockPair.find_all_by(stock_code: code, cross: true)
  end

  def get_stock_pair(pair_or_code)
    pair = pair_or_code.is_a?(Pair) ? pair_or_code : Pair.find_by_code(pair_or_code)
    StockPair.find_all_by(stock_code: code, pair: pair).first
  end

  def stock_currencies(active: nil)
    stock_currencies = StockCurrency.where(stock_code: code).includes(:currency).to_a
    if active
      currencies = downloadable_stock_pairs.map(&:pair).flat_map { |p| [p.base_currency, p.target_currency] }.uniq
      codes = currencies.map(&:code)
      stock_currencies.select! { |sc| sc.app_currency_code.in?(codes) }
    end
    stock_currencies
  end

  def currencies
    Currency.joins(:stock_currencies).where(stock_currencies: {stock_code: code})
  end

  def to_param
    stock_code
  end
end
