module Stocks
  # https://www.kraken.com/help/api#public-market-data
  module Kraken
    def download_order_books(stock_pairs = nil)
      stock_pairs.map do |stock_pair|
        response = get('Depth', pair: stock_pair.api_code)

        if response
          data = response['result'].values.first.slice('asks', 'bids')
          [stock_pair, data]
        end
      end.compact.to_h
    end

    # noinspection RubyStringKeysInHashInspection
    def write_pairs_file
      res = get('AssetPairs')
      pairs = res['result'].values.map do |h|
        base = h['quote'].gsub(/^[ZX]/, '')
        target = h['base'].gsub(/^[ZX]/, '')
        "#{target}_#{base}"
      end.uniq

      stock_data = pairs.map do |pair|
        code1, code2 = pair.split('_')
        c1 = Currency.find_by_code(code1)
        c2 = Currency.find_by_code(code2)
        active = !!c1 && !!c2 && c2.btc?
        puts "#{pair} is active" if active
        pair_data = {'active' => active}
        [pair, pair_data]
      end.to_h

      content = {'stocks' => {'Kraken' => stock_data}}
      File.open('config/stocks/Kraken.yaml', 'w') { |f| f.write(content.to_yaml) }
      true
    end

    def get_raw(action, params = {})
      url = "https://api.kraken.com/0/public/#{action}?#{params.to_query}"
      puts "sending request to #{url}"
      response = RestClient.get url
      response.body
    end

    def get(action, params = {})
      JSON.parse(get_raw(action, params))
    end

    def serialize_pair(target_code, base_code)
      "#{target_code.upcase}#{base_code.upcase}"
    end
  end
end
