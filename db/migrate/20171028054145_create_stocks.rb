class CreateStocks < ActiveRecord::Migration[5.1]
  def change
    create_table :stocks, id: false do |t|
      t.string :code, null: false
      t.index :code, unique: true

      t.float :buy_fee
      t.float :sell_fee
    end
  end
end
