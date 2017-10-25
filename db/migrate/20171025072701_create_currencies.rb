class CreateCurrencies < ActiveRecord::Migration[5.1]
  def change
    create_table :currencies, id: false do |t|
      t.string :code, null: false
      t.index :code, unique: true
    end

    %w(bcc bch btc cny dash etc eth eur gno iot ltc mtl neo omg qtum usd usdt xem xmr xrp zec lsk waves strat doge steem).each do |code|
      Currency.create!(code: code)
    end
  end
end
