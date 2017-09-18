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
      json = File.read('db/yobit-pairs.json')
      JSON.parse(json)['pairs']
    end

    def download_order_books(pairs = nil)
      pairs ||= valid_pairs
      code = pairs.map(&:underscored_code).join('-')
      hash = get("depth/#{code}")
      pairs.map do |pair|
        data = hash[pair.underscored_code]
        [pair, data] if data
      end.compact.to_h
    end

    def get_raw(path)
      puts "sending request to #{path}"
      response = RestClient.get "https://yobit.net/api/3/#{path}"
      response.body
    end

    def get(path)
      JSON.parse(get_raw(path))
    end

    # noinspection RubyStringKeysInHashInspection
    def conversion_table
      {'omg' => 'omgame', 'bcc' => 'bch'}
    end


    module NotUsed
      def info
        @info ||= get('info')
      end

      # yobit specific
      def ticker
        @ticker ||= get("ticker/#{valid_pairs.join('-')}")
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

      def get_pairs
        data = {pairs: info['pairs'].keys}
        File.open('db/yobit-pairs.json', 'w') { |f| f.write(data.to_json) }
      end
    end
  end
end
