module Stocks
  class Yobit < Base
    def download_order_books(stock_pairs = nil)
      stock_pairs ||= downloadable_pairs
      code = stock_pairs.map(&:api_code).join('-')
      hash = get("depth/#{code}")
      stock_pairs.map do |stock_pair|
        data = hash[stock_pair.api_code]
        [stock_pair, data] if data
      end.compact.to_h
    end

    def get_raw(path)
      url = "https://yobit.net/api/3/#{path}"
      puts "sending request to #{url}"
      response = RestClient.get url
      response.body
    end

    def get(path)
      JSON.parse(get_raw(path))
    end

    def serialize_pair(target_code, base_code)
      "#{target_code.downcase}_#{base_code.downcase}"
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
