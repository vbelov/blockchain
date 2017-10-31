class PopulateStockCurrencies < ActiveRecord::Migration[5.1]
  # noinspection RubyStringKeysInHashInspection
  def up
    global_currency_codes = Currency.all.map(&:code)

    %w(Yobit Poloniex Exmo Livecoin Bittrex Kraken Cexio Bitfinex Liqui Bter Bitstamp).sort.each do |stock_code|
      content = YAML.load_file("config/stocks/#{stock_code}.yaml")
      currency_codes = []
      content['stocks'][stock_code].keys.each do |code_in_stock|
        currency_codes += code_in_stock.split('_')
      end
      currency_codes = currency_codes.uniq.map(&:downcase).sort

      substitutions =
          case stock_code
            when 'Bitfinex'
              {'dsh' => 'dash'}
            when 'Bittrex'
              {'bcc' => 'bch'}
            when 'Bter'
              {'bcc' => 'bch'}
            when 'Kraken'
              {'xbt' => 'btc'}
            when 'Liqui'
              {'bcc' => 'bch'}
            when 'Yobit'
              {'bcc' => 'bch'}
            else
              {}
          end

      currency_codes.each do |code|
        app_code = substitutions[code] || code

        unless global_currency_codes.include?(app_code)
          Currency.create!(code: app_code, active: false)
          global_currency_codes << app_code
        end

        StockCurrency.create!(
            stock_code: stock_code,
            stock_currency_code: code,
            app_currency_code: app_code,
        )
      end
    end
  end

  def down
    StockCurrency.delete_all
    Currency.where(active: false).delete_all
  end
end
