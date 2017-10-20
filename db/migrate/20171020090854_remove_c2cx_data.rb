class RemoveC2cxData < ActiveRecord::Migration[5.1]
  def change
    Glass.where(stock_code: 'C2cx').delete_all
  end
end
