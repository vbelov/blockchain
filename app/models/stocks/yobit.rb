module Stocks
  module Yobit
    def download_order_books(stock_pairs = nil)
      code = stock_pairs.map(&:api_code).join('-')
      hash = get("depth/#{code}")
      stock_pairs.map do |stock_pair|
        data = hash[stock_pair.api_code]
        [stock_pair, data] if data
      end.compact.to_h
    end

    def get_raw(path)
      url = "https://yobit.net/api/3/#{path}"
      puts "sending request to #{url}"
      response = RestClient.get url
      response.body
    end

    def get(path)
      JSON.parse(get_raw(path))
    end

    def serialize_pair(target_code, base_code)
      "#{target_code.downcase}_#{base_code.downcase}"
    end


    module NotUsed
      def info
        @info ||= get('info')
      end

      # yobit specific
      def ticker
        @ticker ||= get("ticker/#{pair_codes.join('-')}")
      end

      def get_pairs
        data = {pairs: info['pairs'].keys}
        File.open('db/yobit-pairs.json', 'w') { |f| f.write(data.to_json) }
      end
    end
  end
end
