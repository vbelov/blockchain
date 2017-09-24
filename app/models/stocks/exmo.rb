module Stocks
  module Exmo
    def download_order_books(pairs = nil)
      pairs ||= downloadable_pairs
      code = pairs.map(&:api_code).join(',')
      hash = get(:order_book, pair: code)
      pairs.map do |stock_pair|
        code = stock_pair.api_code
        data = hash[code]
        if data
          # noinspection RubyStringKeysInHashInspection
          data = {'asks' => data['ask'], 'bids' => data['bid']}
          [stock_pair, data]
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

    def serialize_pair(target_code, base_code)
      "#{target_code.upcase}_#{base_code.upcase}"
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
