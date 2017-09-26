class ActivateCurrencies
  # noinspection RubyStringKeysInHashInspection
  def run
    currencies = %w(ZEC LSK WAVES STRAT DOGE STEEM)

    Stock.all.each do |stock|
      stock_code = stock.code
      content = YAML.load_file("config/stocks/#{stock_code}.yaml")
      stock_data = content['stocks'][stock_code]
      stock_data.each do |code_in_stock, pair_data|
        code1, code2 = code_in_stock.split('_')
        if code1.in?(currencies) && code2.in?(%w(BTC XBT))
          puts "activating #{code_in_stock} on #{stock_code}"
          pair_data['active'] = true
        end
      end

      content = {'stocks' => {stock_code => stock_data}}
      File.open("config/stocks/#{stock_code}.yaml", 'w') { |f| f.write(content.to_yaml) }
    end

    true
  end
end
