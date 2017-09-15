class CreateGlasses < ActiveRecord::Migration[5.1]
  def change
    create_table :glasses do |t|
      t.string :stock_code
      t.string :target_code
      t.string :base_code
      t.text :buy_orders
      t.text :sell_orders

      t.timestamps
    end
  end
end
