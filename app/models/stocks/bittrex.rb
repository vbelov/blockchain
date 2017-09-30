module Stocks
  module Bittrex
    def download_order_books(stock_pairs = nil)
      stock_pairs.map do |stock_pair|
        response = get('getorderbook', {market: stock_pair.api_code, type: 'both'})

        if response
          asks = response['result']['sell'].map { |h| [h['Rate'], h['Quantity']] }
          bids = response['result']['buy'].map { |h| [h['Rate'], h['Quantity']] }
          # noinspection RubyStringKeysInHashInspection
          data = {'asks' => asks, 'bids' => bids}

          [stock_pair, data]
        end
      end.compact.to_h
    end

    # noinspection RubyStringKeysInHashInspection
    def write_pairs_file
      res = get('getmarkets')
      stock_data = res['result']
          .map { |h| h['MarketName'] }
          .map { |name| name.split('-').reverse.join('_') }
          .map { |p|
        code1, code2 = p.split('_')
        c1 = Currency.find_by_code(code1)
        c2 = Currency.find_by_code(code2)
        active = !!c1 && !!c2 && code2 == 'BTC'
        puts "#{p} is active" if active
        pair_data = {'active' => active}
        [p, pair_data]
      }.to_h

      content = {'stocks' => {'Bittrex' => stock_data}}
      File.open('config/stocks/Bittrex.yaml', 'w') { |f| f.write(content.to_yaml) }
      true
    end

    def get_raw(action, params = {})
      url = "https://bittrex.com/api/v1.1/public/#{action}?#{params.to_query}"
      puts "sending request to #{url}"
      response = RestClient.get url
      response.body
    end

    def get(action, params = {})
      JSON.parse(get_raw(action, params))
    end

    def serialize_pair(target_code, base_code)
      "#{base_code.upcase}-#{target_code.upcase}"
    end
  end
end
