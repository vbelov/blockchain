module Stocks
  # https://bter.com/api
  module Bter
    # noinspection RubyStringKeysInHashInspection
    def download_order_books(stock_pairs = nil)
      stock_pairs ||= downloadable_pairs
      stock_pairs.map do |stock_pair|
        response = get("depth/#{stock_pair.api_code}")
        if response['result'] == 'true'
          asks = response['asks'].reverse
          bids = response['bids']
          data = {'asks' => asks, 'bids' => bids}
          [stock_pair, data]
        end
      end.compact.to_h
    end

    # noinspection RubyStringKeysInHashInspection
    def write_pairs_file
      pairs = get('pairs')
      stock_data = pairs.map do |pair|
        pair = pair.upcase
        code1, code2 = pair.split('_')
        c1 = Currency.find_by_code(code1)
        c2 = Currency.find_by_code(code2)
        active = !!c1 && !!c2 && c2.btc?
        puts "#{pair} is active" if active
        pair_data = {'active' => active}
        [pair, pair_data]
      end.compact.to_h

      content = {'stocks' => {'Bter' => stock_data}}
      File.open('config/stocks/Bter.yaml', 'w') { |f| f.write(content.to_yaml) }
      true
    end

    def get_raw(action, params = {})
      url = "http://data.bter.com/api/1/#{action}?#{params.to_query}"
      puts "sending request to #{url}"
      response = RestClient.get url
      response.body
    end

    def get(action, params = {})
      JSON.parse(get_raw(action, params))
    end

    def serialize_pair(target_code, base_code)
      "#{target_code.downcase}_#{base_code.downcase}"
    end
  end
end
