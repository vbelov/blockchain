module Stocks
  class Poloniex < Base
    def download_order_books(pairs = nil)
      pairs ||= valid_pairs

      pairs.map do |pair|
        hash = get(command: 'returnOrderBook', currencyPair: pair_to_code(pair), depth: 100)
        [pair, hash] if hash
      end.compact.to_h
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

    def pair_to_code(pair)
      "#{currency_to_code(pair.base_currency)}_#{currency_to_code(pair.target_currency)}"
    end

    def serialize_currency_code(code)
      code.upcase
    end


    module NotUsed
      def order_book
        get(command: 'returnOrderBook', currencyPair: 'BTC_ETH', depth: 50)
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
