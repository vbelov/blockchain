desc 'Delete glass data older than one week'
task delete_old_data: :environment do
  codes = Stock.all_codes - %w(Poloniex Bitfinex)
  codes.each do |code|
    puts "Deleting #{code} data ..."
    Glass.where(stock_code: code).where('time < ?', 1.week.ago).delete_all
  end
end
