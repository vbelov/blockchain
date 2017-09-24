class StockPair
  include Virtus.model

  attribute :stock_code, String
  attribute :pair, Pair
  attribute :code_in_stock, String
  attribute :active, Boolean
  attribute :visible, Boolean

  attribute :cross, Boolean
  attribute :base_pair_code, String
  attribute :target_pair_code, String

  delegate :target_code, :base_code, :slashed_code, to: :pair

  class << self
    def all
      @all ||= Stock.all.flat_map do |stock|
        stock_code = stock.code
        content = YAML.load_file("config/stocks/#{stock_code}.yaml")
        content['stocks'][stock_code].map do |code_in_stock, pair_data|
          active = pair_data['active']
          visible = pair_data.fetch('visible', active)
          cross = pair_data.fetch('cross', false)

          if active || visible
            code_in_app = pair_data['real_code'] || code_in_stock
            pair = Pair.find_by_code(code_in_app)

            stock_pair = StockPair.new(
                stock_code: stock_code,
                pair: pair,
                code_in_stock: code_in_stock,
                active: active,
                visible: visible,
                cross: cross,
            )
            if cross
              stock_pair.base_pair_code = pair_data['base_pair']
              stock_pair.target_pair_code = pair_data['target_pair']
            end

            stock_pair
          end
        end.compact
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
    @api_code ||= stock.serialize_pair(*code_in_stock.split('_'))
  end

  def base_pair
    @base_pair ||= self.class.find_all_by(stock_code: stock_code, code_in_stock: base_pair_code).first
  end

  def target_pair
    @target_pair ||= self.class.find_all_by(stock_code: stock_code, code_in_stock: target_pair_code).first
  end

  def downloadable?
    active
  end

  def cross_pair?
    cross
  end
end
