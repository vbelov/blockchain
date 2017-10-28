class PopulateStocks < ActiveRecord::Migration[5.1]
  def change
    %w(Yobit Poloniex Exmo Livecoin Bittrex Kraken Cexio Bitfinex Liqui Bter Bitstamp).sort.each do |code|
      Stock.create!(code: code)
    end
  end
end
