module Stocks
  class Exmo < Base
    def pairs
      json = File.read('db/exmo-pairs.json')
      JSON.parse(json)['pairs']
    end

    def download_order_books(pairs = nil)
      pairs ||= valid_pairs
      code = pairs.map { |p| pair_to_code(p) }.join(',')
      hash = get(:order_book, pair: code)
      pairs.map do |pair|
        code = pair_to_code(pair)
        data = hash[code]
        if data
          asks = data['ask'].map { |r| r.map(&:to_f) }
          bids = data['bid'].map { |r| r.map(&:to_f) }
          # noinspection RubyStringKeysInHashInspection
          data = {'asks' => asks, 'bids' => bids}
          [pair, data]
        end
      end.compact.to_h
    end

    def get_raw(action, params = {})
      url = "https://api.exmo.com/v1/#{action}/?#{params.to_query}"
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


    module NotUsed
      def ticker
        @ticker ||= get(:ticker)
      end

      def get_pairs
        data = {pairs: ticker.keys}
        File.open('db/exmo-pairs.json', 'w') { |f| f.write(data.to_json) }
      end
    end
  end
end
