module Stocks
  class Poloniex < Base
    def get_glass_impl(vector)
      pair_code = "#{currency_to_code(vector.base_currency)}_#{currency_to_code(vector.target_currency)}"

      hash =
          with_cache("depth-#{pair_code}.json") do
            get_raw(command: 'returnOrderBook', currencyPair: pair_code, depth: 100)
          end
      part = vector.sell? ? 'bids' : 'asks'
      hash[part]
    end

    def pairs
      json = File.read('db/poloniex-pairs.json')
      JSON.parse(json)['pairs'].map { |pair| pair.split('_').reverse.join('_') }
    end

    def get_raw(options)
      url = "https://poloniex.com/public?#{options.to_query}"
      puts "sending request to #{url}"
      response = RestClient.get url
      response.body
    end

    def get(options)
      JSON.parse(get_raw(options))
    end

    # noinspection RubyStringKeysInHashInspection
    def conversion_table
      {'bch' => 'bcc'}
    end

    def serialize_currency_code(code)
      code.upcase
    end


    module NotUsed
      def order_book
        get(command: 'returnOrderBook', currencyPair: 'BTC_ETH', depth: 10)
      end

      def all_books
        get(command: 'returnOrderBook', currencyPair: 'all', depth: 10)
      end

      def ticker
        get(command: 'returnTicker')
      end

      def get_pairs
        data = {pairs: ticker.keys}
        File.open('db/poloniex-pairs.json', 'w') { |f| f.write(data.to_json) }
      end
    end
  end
end
