class AddIndicesToGlasses < ActiveRecord::Migration[5.1]
  def change
    add_index :glasses, :time
    add_index :glasses, :stock_code
    add_index :glasses, :target_code
    add_index :glasses, :base_code
  end
end
