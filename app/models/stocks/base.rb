module Stocks
  class Base
    def valid_pairs
      @valid_pairs ||=
          pairs.map do |pair|
            code1, code2 = pair.split('_').map(&:downcase)
            next unless code2 == 'btc'
            c1 = Currency.find_by_code(code1)
            c2 = Currency.find_by_code(code2)
            if c1 && c2
              Pair.new(
                  target_currency: c1,
                  base_currency: c2,
              )
            end
          end.compact
    end

    def glass(vector)
      g = get_glass_impl(vector).map do |rate, volume|
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
      orders = glass(vector)
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
      preload_glasses

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

    def preload_glasses
    end

    # ============= Helper methods =================

    # generic
    def with_cache(filename, &block)
      cache = Rails.env.development?
      if cache
        path = "tmp/cache/#{self.class.name.demodulize.underscore}-#{filename}"
        if File.exists?(path)
          json = File.read(path)
        else
          json = yield
          File.open(path, 'w+') { |f| f.write(json) }
        end
      else
        json = memory_cache(filename, &block)
      end
      JSON.parse(json)
    end

    # generic
    def memory_cache(filename)
      @memory_cache ||= {}
      res = @memory_cache[filename]
      res = @memory_cache[filename] = yield unless res
      res
    end
  end
end
