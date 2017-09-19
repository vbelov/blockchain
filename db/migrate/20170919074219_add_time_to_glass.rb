class AddTimeToGlass < ActiveRecord::Migration[5.1]
  def change
    add_column :glasses, :time, :datetime
  end
end
