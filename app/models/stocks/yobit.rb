# A / B
# Покупка: сколько B я должен заплатить, чтобы купить 1 A
# Ордера на продажу (asks): другие чуваки продают A за B

# Продажа: сколько B я получу за один A
# Ордера на покупку (bids): другие чуваки покупают A за B

# стартуем с X единиц валюты A
# смотрим, сколько примерно это будет в каждой из валют
# смотрим средневзвешенный курс в каждой паре
module Stocks
  class Yobit
    def currencies
      %w(btc eth bcc xrp ltc xem dash xmr iot etc omg gno neo qtum mtl)
      # %w(btc eth ltc)
    end

    def valid_pairs
      @valid_pairs ||=
          info['pairs'].keys.select do |pair|
            c1, c2 = pair.split('_')
            c1.in?(currencies) && c2.in?(currencies)
          end
    end

    def info
      @info ||= with_cache('info.json') { get('info') }
    end

    def with_cache(filename)
      path = "tmp/cache/#{filename}"
      if File.exists?(path)
        json = File.read(path)
      else
        json = yield
        File.open(path, 'w+') { |f| f.write(json) }
      end
      JSON.parse(json)
    end

    def valid_pairs_info
      info.merge('pairs' => info['pairs'].slice(*valid_pairs))
    end

    def cached_glass(pair_code = 'eth_btc')
      with_cache("depth-#{pair_code}.json") do
        get "depth/#{pair_code}"
      end
    end

    def glass(pair_code = 'eth_btc')
      # JSON.parse(get("depth/#{pair_code}"))
      cached_glass(pair_code)
    end

    def ticker
      @ticker ||= with_cache('ticker.json') { get("ticker/#{valid_pairs.join('-')}") }
    end

    class NoAmount < RuntimeError; end

    def price(my_currency, my_amount, target_currency)
      # puts "loading price #{my_amount} #{my_currency} => #{target_currency}"
      pair, direction, aaa = find_pair(my_currency, target_currency)
      hash = glass(pair)
      amount_left = my_amount
      target_currency_total_amount = 0
      hash[pair][direction].take_while do |order|
        exchange_rate = order[0]
        exchange_rate = 1.0 / exchange_rate unless aaa
        target_currency_order_amount = order[1]
        my_currency_order_amount = exchange_rate * target_currency_order_amount
        if amount_left > my_currency_order_amount
          amount_left -= my_currency_order_amount
          target_currency_total_amount += target_currency_order_amount
          true
        else
          target_currency_total_amount += amount_left / exchange_rate
          amount_left = 0
          false
        end
      end
      raise NoAmount, "failed to collect amount in currency #{target_currency}" unless amount_left == 0

      target_currency_total_amount
    end

    def find_pair(currency_to_sell, currency_to_buy)
      pair1 = "#{currency_to_sell}_#{currency_to_buy}"
      pair2 = "#{currency_to_buy}_#{currency_to_sell}"
      if valid_pairs.include?(pair1)
        [pair1, 'asks', false]
      elsif valid_pairs.include?(pair2)
        [pair2, 'bids', true]
      else
        raise 'pair not found'
      end
    end

    def approximate_exchange_rates
      @approximate_exchange_rates ||=
          begin
            rates = []
            valid_pairs.each do |pair|
              avg = ticker[pair]['avg']
              rates << [pair, avg]
              another_pair = pair.split('_').reverse.join('_')
              rates << [another_pair, 1.0 / avg]
            end
            rates.to_h
          end
    end

    def approximate_amounts(base_currency, base_amount)
      currencies.map do |currency|
        next [currency, base_amount] if currency == base_currency
        pair = "#{base_currency}_#{currency}"
        rate = approximate_exchange_rates[pair]
        if rate
          [currency, rate * base_amount]
        else
          [currency, nil]
        end
      end.to_h
    end

    def current_exchange_rates(base_currency, base_amount)
      amounts = approximate_amounts(base_currency, base_amount)

      valid_pairs.flat_map do |pair|
        pair.split('_').permutation(2).to_a.map do |currency1, currency2|
          p = "#{currency2}_#{currency1}"

          begin
            amount = amounts[currency1]
            pr = price(currency1, amount, currency2)
            rate = amount / pr
            [p, rate]
          rescue NoAmount => err
            puts err.message
            [p, nil]
          end
        end
      end.to_h
    end

    def get(path)
      puts "sending request to #{path}"
      response = RestClient.get "https://yobit.net/api/3/#{path}"
      response.body
    end

    def clear_cache
      FileUtils.rm_rf Dir.glob('cache/*')
    end
  end
end

# ap Stocks::Yobit.new.current_exchange_rates('btc', 0.1)
