module Stocks
  # https://bitfinex.readme.io/v2/reference
  module Bitfinex
    # noinspection RubyStringKeysInHashInspection
    def download_order_books(stock_pairs = nil)
      stock_pairs.map do |stock_pair|
        orders = get("book/t#{stock_pair.api_code}/P0")
        bids, asks = orders
                         .partition { |_, _, volume| volume > 0 }
                         .map { |book| book.map { |rate, _, volume| [rate, volume.abs] } }
        data = {'bids' => bids, 'asks' => asks}
        [stock_pair, data]
      end.compact.to_h
    end

    # noinspection RubyStringKeysInHashInspection
    def write_pairs_file
      url = 'https://api.bitfinex.com/v1/symbols'
      puts "sending request to #{url}"
      response = RestClient.get url
      pairs = JSON.parse(response.body)
      stock_data = pairs.map do |pair|
        if pair.size == 6
          code1 = pair[0, 3].upcase
          code2 = pair[3, 3].upcase
          pair = "#{code1}_#{code2}"
          c1 = Currency.find_by_code(code1)
          c2 = Currency.find_by_code(code2)
          active = !!c1 && !!c2 && c2.btc?
          puts "#{pair} is active" if active
          pair_data = {'active' => active}
          [pair, pair_data]
        else
          puts "unexpected size of pair: #{pair}"
        end
      end.compact.to_h

      content = {'stocks' => {'Bitfinex' => stock_data}}
      File.open('config/stocks/Bitfinex.yaml', 'w') { |f| f.write(content.to_yaml) }
      true
    end

    def get_raw(action, params = {})
      url = "https://api.bitfinex.com/v2/#{action}?#{params.to_query}"
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
