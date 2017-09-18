class PeriodicRefresher
  def run
    counter = 0

    loop do
      begin
        my_sleep
        stocks.each do |stock|
          puts "updating #{stock.stock_code} ..."
          stock.refresh_glasses
        end
        counter += 1
          # break if counter == 1
      rescue => err
        puts '===================  ERROR  ===================='
        puts err.message
        err.backtrace.each { |l| puts l }
      end
    end
  end

  private

  def stocks
    Stock.all.map { |c| Stocks.const_get(c).new }
  end

  def my_sleep
    seconds = 60 - Time.now.sec
    puts "going to sleep for #{seconds} seconds"
    sleep(seconds)
  end
end
