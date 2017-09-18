module Stocks
  class Livecoin < Base
    def pairs
      json = File.read('db/livecoin-pairs.json')
      JSON.parse(json)['pairs']
    end

    def download_order_books(pairs = nil)
      pairs ||= valid_pairs

      pairs.map do |pair|
        hash = get('order_book', currencyPair: pair_to_code(pair))
        if hash
          asks = hash['asks'].map { |r| r.map(&:to_f) }
          bids = hash['bids'].map { |r| r.map(&:to_f) }
          # noinspection RubyStringKeysInHashInspection
          hash = {'asks' => asks, 'bids' => bids}
          [pair, hash]
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

    def serialize_currency_code(code)
      code.upcase
    end

    def pair_to_code(pair)
      "#{currency_to_code(pair.target_currency)}/#{currency_to_code(pair.base_currency)}"
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
