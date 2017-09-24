module Stocks
  module Poloniex
    def download_order_books(stock_pairs = nil)
      stock_pairs ||= downloadable_pairs

      stock_pairs.map do |stock_pair|
        hash = get(command: 'returnOrderBook', currencyPair: stock_pair.api_code, depth: 100)
        [stock_pair, hash] if hash
      end.compact.to_h
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

    def serialize_pair(target_code, base_code)
      "#{base_code.upcase}_#{target_code.upcase}"
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
