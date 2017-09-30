module Stocks
  # https://cex.io/rest-api
  module Cexio
    def download_order_books(stock_pairs = nil)
      stock_pairs.map do |stock_pair|
        response = get("order_book/#{stock_pair.api_code}")
        if response
          data = response.slice('bids', 'asks')
          [stock_pair, data]
        end
      end.compact.to_h
    end

    # noinspection RubyStringKeysInHashInspection
    def write_pairs_file
      res = get('currency_limits')
      stock_data = res['data']['pairs'].map do |h|
        code1 = h['symbol1']
        code2 = h['symbol2']
        pair = "#{code1}_#{code2}"
        c1 = Currency.find_by_code(code1)
        c2 = Currency.find_by_code(code2)
        active = !!c1 && !!c2 && c2.btc?
        puts "#{pair} is active" if active
        pair_data = {'active' => active}
        [pair, pair_data]
      end.to_h

      content = {'stocks' => {'Cexio' => stock_data}}
      File.open('config/stocks/Cexio.yaml', 'w') { |f| f.write(content.to_yaml) }
      true
    end

    def get_raw(action, params = {})
      url = "https://cex.io/api/#{action}"
      url = "#{url}?#{params.to_query}" if params.any?
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
  end
end
