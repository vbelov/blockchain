class AddWithdrawalFeeToStockCurrencies < ActiveRecord::Migration[5.1]
  def change
    add_column :stock_currencies, :withdrawal_fee, :float
  end
end
