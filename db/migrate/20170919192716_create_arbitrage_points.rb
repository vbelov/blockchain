class CreateArbitragePoints < ActiveRecord::Migration[5.1]
  def change
    create_table :arbitrage_points do |t|
      t.integer :arbitrage_period_id
      t.datetime :time
      t.float :max_revenue
      t.float :volume

      t.timestamps
    end
  end
end
