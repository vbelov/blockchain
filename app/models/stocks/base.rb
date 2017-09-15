module Stocks
  class Base
    def stock_code
      self.class.name.demodulize
    end

    def valid_pairs
      @valid_pairs ||=
          pairs.map do |pair|
            code1, code2 = pair.split('_').map(&:downcase)
            next unless code2 == 'btc'
            c1 = currency_by_code(code1)
            c2 = currency_by_code(code2)
            if c1 && c2
              Pair.new(
                  target_currency: c1,
                  base_currency: c2,
              )
            end
          end.compact
    end

    def refresh_glasses
      download_order_books.each { |pair, data| save_glass(pair, data) }
    end

    def save_glass(pair, pair_data)
      Glass.create!(
          stock_code: stock_code,
          target_code: pair.target_code,
          base_code: pair.base_code,
          sell_orders: pair_data['bids'].to_json,
          buy_orders: pair_data['asks'].to_json,
      )
    end

    def refresh_time
      Glass.where(stock_code: stock_code).order(created_at: :desc).first&.created_at
    end

    def find_or_fetch_glass(vector)
      glass = Glass.where(
          stock_code: stock_code,
          target_code: vector.target_code,
          base_code: vector.base_code,
      ).order(created_at: :desc).first

      unless glass
        pair = vector.pair
        pair_data = download_order_books([pair])[pair]
        glass = save_glass(pair, pair_data) if pair_data
      end

      glass
    end

    def get_raw_orders(vector)
      glass = find_or_fetch_glass(vector)
      if glass
        json = glass.send("#{vector.action}_orders")
        JSON.parse(json)
      end
    end

    def get_orders(vector)
      g = get_raw_orders(vector).map do |rate, volume|
        Order.new(
            vector: vector,
            rate: rate,
            target_volume: volume,
        )
      end
      cumulative_volume = 0
      g.each do |o|
        cumulative_volume += o.base_volume
        o.cumulative_volume = cumulative_volume
      end
      g
    end

    def process_glass(vector, amount)
      orders = get_orders(vector)
      base_volume = amount
      target_volume = 0
      orders.each { |o| o.used = :none }
      orders.take_while do |order|
        if base_volume >= order.base_volume
          base_volume -= order.base_volume
          target_volume += order.target_volume
          order.used = :full
          true
        else
          target_volume += base_volume / order.rate
          base_volume = 0
          order.used = :partial
          false
        end
      end
      error = base_volume == 0 ? nil : "Недостаточный объем сделок: #{amount - base_volume} < #{amount}"

      OpenStruct.new(
          orders: orders,
          target_volume: target_volume,
          error: error,
          effective_rate: amount / target_volume,
      )
    end

    def current_exchange_rates(base_currency, base_amount, pairs: nil)
      pairs = pairs
                  &.map { |pair| pair.is_a?(Pair) ? pair : Pair.find_by_code(pair) }
                  &.select { |p| p.in?(valid_pairs) } ||
          valid_pairs
      pairs.map do |pair|
        er = ExchangeRate.new(stock: self.class.name.demodulize, pair: pair)

        [:buy, :sell].each do |action|
          if pair.base_currency == base_currency
            vector = Vector.new(pair: pair, action: action)
            result = process_glass(vector, base_amount)
            er.send("#{action}_rate=", result.effective_rate) unless result.error
          end
        end

        er
      end
    end

    def currency_by_code(code)
      code = conversion_table[code] || code
      Currency.find_by_code(code)
    end

    def currency_to_code(currency)
      table = conversion_table.to_a.map(&:reverse).to_h
      code = table[currency.code] || currency.code
      serialize_currency_code(code)
    end

    def pair_to_code(pair)
      "#{currency_to_code(pair.base_currency)}_#{currency_to_code(pair.target_currency)}"
    end

    def conversion_table
      {}
    end

    def serialize_currency_code(code)
      code
    end
  end
end
