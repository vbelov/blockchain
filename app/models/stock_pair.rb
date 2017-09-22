class StockPair
  include Virtus.model

  attribute :stock_code, String
  attribute :pair, Pair
  attribute :code_in_stock, String
  attribute :active, Boolean
  attribute :visible, Boolean

  attribute :cross, Boolean
  attribute :base_pair, StockPair
  attribute :secondary_pair, StockPair

  delegate :target_code, :base_code, to: :pair

  class << self
    def all
      @all ||= Stock.all.flat_map do |stock_code|
        content = YAML.load_file("config/stocks/#{stock_code}.yaml")
        content['stocks'][stock_code].map do |code_in_stock, pair_data|
          code_in_app = pair_data['real_code'] || code_in_stock
          pair = Pair.find_by_code(code_in_app)

          active = pair_data['active']
          StockPair.new(
              stock_code: stock_code,
              pair: pair,
              code_in_stock: code_in_stock,
              active: active,
              visible: active,
              cross: false,
          )
        end
      end
    end

    def find_all_by(filters)
      all.select do |stock_pair|
        filters.all? do |key, val|
          stock_pair.send(key) == val
        end
      end
    end
  end

  def stock
    @stock ||= Stock.find_by_code(stock_code)
  end

  def api_code
    @api_code ||= stock.api.serialize_pair(*code_in_stock.split('_'))
  end
end
