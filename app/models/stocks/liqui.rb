module Stocks
  # https://liqui.io/api
  module Liqui
    # noinspection RubyStringKeysInHashInspection
    def download_order_books(stock_pairs = nil)
      stock_pairs ||= downloadable_pairs
      # stock_pairs.select! { |p| p.api_code == 'dash_btc' }
      stock_pairs.map do |stock_pair|
        response = get("depth/#{stock_pair.api_code}")
        data = response[stock_pair.api_code]
        if data.is_a?(Hash) && data.key?('asks')
          [stock_pair, data]
        end
      end.compact.to_h
    end

    # noinspection RubyStringKeysInHashInspection
    def write_pairs_file
      response = get('info')
      pairs = response['pairs'].keys
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

      content = {'stocks' => {'Liqui' => stock_data}}
      File.open('config/stocks/Liqui.yaml', 'w') { |f| f.write(content.to_yaml) }
      true
    end

    def get_raw(action, params = {})
      url = "https://api.liqui.io/api/3/#{action}?#{params.to_query}"
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
