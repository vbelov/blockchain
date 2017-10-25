class CreateStockCurrencies < ActiveRecord::Migration[5.1]
  def change
    create_table :stock_currencies do |t|
      t.string :stock_code, null: false
      t.string :stock_currency_code, null: false
      t.string :app_currency_code, null: false
      t.index [:stock_code, :app_currency_code], unique: true
    end
    add_foreign_key :stock_currencies, :currencies, column: :app_currency_code, primary_key: :code
  end
end
