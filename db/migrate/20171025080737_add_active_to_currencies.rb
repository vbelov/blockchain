class AddActiveToCurrencies < ActiveRecord::Migration[5.1]
  def change
    add_column :currencies, :active, :boolean, default: false
    Currency.update_all(active: true)
  end
end
