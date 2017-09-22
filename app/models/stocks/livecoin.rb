module Stocks
  class Livecoin < Base
    def download_order_books(stock_pairs = nil)
      stock_pairs ||= downloadable_pairs

      stock_pairs.map do |stock_pair|
        hash = get('order_book', currencyPair: stock_pair.api_code)
        if hash
          # noinspection RubyStringKeysInHashInspection
          hash = {'asks' => hash['asks'], 'bids' => hash['bids']}
          [stock_pair, hash]
        end
      end.compact.to_h
    end

    def get_raw(action, params = {})
      url = "https://api.livecoin.net/exchange/#{action}/?#{params.to_query}"
      puts "sending request to #{url}"
      response = RestClient.get url
      response.body
    end

    def get(action, params = {})
      JSON.parse(get_raw(action, params))
    end

    def serialize_pair(target_code, base_code)
      "#{target_code.upcase}/#{base_code.upcase}"
    end


    module NotUsed
      def ticker
        @ticker ||= get(:ticker)
      end

      def get_pairs
        data = {pairs: ticker.map { |h| h['symbol'].sub('/', '_') }}
        File.open('db/livecoin-pairs.json', 'w') { |f| f.write(data.to_json) }
      end
    end
    include NotUsed
  end
end
