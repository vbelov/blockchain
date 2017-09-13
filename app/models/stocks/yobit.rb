# A / B
# Покупка: сколько B я должен заплатить, чтобы купить 1 A
# Ордера на продажу (asks): другие чуваки продают A за B

# Продажа: сколько B я получу за один A
# Ордера на покупку (bids): другие чуваки покупают A за B

# стартуем с X единиц валюты A
# смотрим, сколько примерно это будет в каждой из валют
# смотрим средневзвешенный курс в каждой паре
module Stocks
  class Yobit
    def currencies
      %w(btc eth bcc xrp ltc xem dash xmr iot etc omg gno neo qtum mtl)
      # %w(btc eth ltc)
    end

    def valid_pairs
      @valid_pairs ||=
          info['pairs'].keys.select do |pair|
            c1, c2 = pair.split('_')
            c1.in?(currencies) && c2.in?(currencies)
          end
    end

    def info
      @info ||= with_cache('info.json') { get('info') }
    end

    def with_cache(filename, &block)
      cache = Rails.env.development?
      if cache
        path = "tmp/cache/#{filename}"
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

    def memory_cache(filename)
      @memory_cache ||= {}
      res = @memory_cache[filename]
      res = @memory_cache[filename] = yield unless res
      res
    end

    def valid_pairs_info
      info.merge('pairs' => info['pairs'].slice(*valid_pairs))
    end

    def cached_glass(pair_code = 'eth_btc')
      with_cache("depth-#{pair_code}.json") do
        get "depth/#{pair_code}"
      end
    end

    class Order
      include Virtus.model

      attribute :target_currency, String
      attribute :base_currency, String
      attribute :action, Symbol # :buy, :sell
      attribute :rate, Float
      attribute :target_volume, Float
      attribute :cumulative_volume, Float
      attribute :used, Symbol # :full, :partial, :none

      def base_volume
        rate * target_volume
      end
    end

    def glass(pair_code = 'eth_btc', action)
      # JSON.parse(get("depth/#{pair_code}"))
      hash = cached_glass(pair_code)
      part = action == :sell ? 'bids' : 'asks'
      tc, bc = pair_code.split('_')
      g = hash[pair_code][part].map do |rate, volume|
        Order.new(
            target_currency: tc,
            base_currency: bc,
            action: action,
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

    def ticker
      @ticker ||= with_cache('ticker.json') { get("ticker/#{valid_pairs.join('-')}") }
    end

    def process_glass(target_currency, base_currency, action, amount)
      pair = "#{target_currency}_#{base_currency}"
      orders = glass(pair, action)
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

    class ExchangeRate
      include Virtus.model

      attribute :target_currency, String
      attribute :base_currency, String
      attribute :buy_rate, Float
      attribute :sell_rate, Float
    end

    def current_exchange_rates(base_currency, base_amount)
      hash = JSON.parse(get("depth/#{valid_pairs.join('-')}"))
      @memory_cache ||= {}
      valid_pairs.each do |pair|
        key = "depth-#{pair}.json"
        @memory_cache[key] = hash.slice(pair).to_json
      end

      valid_pairs.map do |pair|
        tc, bc = pair.split('_')
        er = ExchangeRate.new(
            target_currency: tc,
            base_currency: bc,
        )

        [:buy, :sell].map do |action|
          raise NotImplementedError unless bc == base_currency
          result = process_glass(tc, bc, action, base_amount)
          er.send("#{action}_rate=", result.effective_rate) unless result.error
        end

        er
      end
    end

    def get(path)
      puts "sending request to #{path}"
      response = RestClient.get "https://yobit.net/api/3/#{path}"
      response.body
    end

    def clear_cache
      FileUtils.rm_rf Dir.glob('cache/*')
    end

    # под вопросом
    def approximate_exchange_rates
      @approximate_exchange_rates ||=
          begin
            rates = []
            valid_pairs.each do |pair|
              avg = ticker[pair]['avg']
              rates << [pair, avg]
              another_pair = pair.split('_').reverse.join('_')
              rates << [another_pair, 1.0 / avg]
            end
            rates.to_h
          end
    end

    # под вопросом
    def approximate_amounts(base_currency, base_amount)
      currencies.map do |currency|
        next [currency, base_amount] if currency == base_currency
        pair = "#{base_currency}_#{currency}"
        rate = approximate_exchange_rates[pair]
        if rate
          [currency, rate * base_amount]
        else
          [currency, nil]
        end
      end.to_h
    end
  end
end
