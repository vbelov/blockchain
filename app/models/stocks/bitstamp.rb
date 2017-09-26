module Stocks
  # https://www.bitstamp.net/api/
  module Bitstamp
    # noinspection RubyStringKeysInHashInspection
    def download_order_books(stock_pairs = nil)
      stock_pairs ||= downloadable_pairs
      stock_pairs.map do |stock_pair|
        response = get("order_book/#{stock_pair.api_code}")
        [stock_pair, response.slice('bids', 'asks')]
      end.compact.to_h
    end

    # noinspection RubyStringKeysInHashInspection
    def write_pairs_file
      pairs = %w(btcusd btceur eurusd xrpusd xrpeur xrpbtc ltcusd ltceur ltcbtc ethusd etheur ethbtc)
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

      content = {'stocks' => {'Bitstamp' => stock_data}}
      File.open('config/stocks/Bitstamp.yaml', 'w') { |f| f.write(content.to_yaml) }
      true
    end

    def get_raw(action, params = {})
      url = "https://www.bitstamp.net/api/v2/#{action}?#{params.to_query}"
      puts "sending request to #{url}"
      response = RestClient.get url
      response.body
    end

    def get(action, params = {})
      JSON.parse(get_raw(action, params))
    end

    def serialize_pair(target_code, base_code)
      "#{target_code.downcase}#{base_code.downcase}"
    end
  end
end
