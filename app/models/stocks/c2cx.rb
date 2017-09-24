module Stocks
  module C2cx
    def download_order_books(stock_pairs = nil)
      stock_pairs ||= downloadable_pairs
      stock_pairs.map do |stock_pair|
        response = get('getorderbook', symbol: stock_pair.api_code)
        if response
          data = response['data']
          # noinspection RubyStringKeysInHashInspection
          data = {'asks' => data['asks'].reverse, 'bids' => data['bids']}
          [stock_pair, data]
        end
      end.compact.to_h
    end

    def get_raw(action, params = {})
      url = "https://api.c2cx.com/v1/#{action}?#{params.to_query}"
      puts "sending request to #{url}"
      response = RestClient.get url
      response.body
    end

    def get(action, params = {})
      JSON.parse(get_raw(action, params))
    end

    def serialize_pair(target_code, base_code)
      "#{base_code.upcase}_#{target_code.upcase}"
    end
  end
end
