class RenameBcc < ActiveRecord::Migration[5.1]
  def change
    Glass.where(stock_code: %w(Yobit Poloniex), target_code: 'bcc').update_all(target_code: 'bch')
  end
end
