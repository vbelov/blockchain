class CreateArbitragePeriods < ActiveRecord::Migration[5.1]
  def change
    create_table :arbitrage_periods do |t|
      t.string :buy_stock_code
      t.string :sell_stock_code
      t.string :target_code
      t.string :base_code
      t.datetime :started_at
      t.datetime :finished_at
      t.integer :duration
      t.float :max_revenue
      t.float :volume
      t.float :max_arbitrage

      t.timestamps
    end
  end
end
