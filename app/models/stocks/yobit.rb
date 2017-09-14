# A / B
# Покупка: сколько B я должен заплатить, чтобы купить 1 A
# Ордера на продажу (asks): другие чуваки продают A за B

# Продажа: сколько B я получу за один A
# Ордера на покупку (bids): другие чуваки покупают A за B

# стартуем с X единиц валюты A
# смотрим, сколько примерно это будет в каждой из валют
# смотрим средневзвешенный курс в каждой паре
module Stocks
  class Yobit < Base
    def pairs
      info['pairs'].keys
    end

    def info
      @info ||= with_cache('info.json') { get('info') }
    end

    def get_glass_impl(vector)
      pair_code = "#{vector.target_code}_#{vector.base_code}"
      hash =
          with_cache("depth-#{pair_code}.json") do
            get "depth/#{pair_code}"
          end
      part = vector.sell? ? 'bids' : 'asks'
      hash[pair_code][part]
    end

    def preload_glasses
      hash = JSON.parse(get("depth/#{valid_pairs.map(&:underscored_code).join('-')}"))
      @memory_cache ||= {}
      valid_pairs.each do |pair|
        key = "depth-#{pair}.json"
        @memory_cache[key] = hash.slice(pair).to_json
      end
    end

    def get(path)
      puts "sending request to #{path}"
      response = RestClient.get "https://yobit.net/api/3/#{path}"
      response.body
    end


    module NotUsed
      def clear_cache
        FileUtils.rm_rf Dir.glob('cache/*')
      end

      # yobit specific
      def ticker
        @ticker ||= with_cache('ticker.json') { get("ticker/#{valid_pairs.join('-')}") }
      end

      def valid_pairs_info
        info.merge('pairs' => info['pairs'].slice(*valid_pairs))
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
end
