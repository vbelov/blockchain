class PeriodicRefresher
  def self.run
    threads = Stock.all.map do |stock|
      Thread.new do
        new(stock).run
      end
    end
    threads.each(&:join)
  end

  def initialize(stock)
    @stock = stock
  end

  def run
    counter = 0

    loop do
      begin
        my_sleep
        puts "updating #{@stock.stock_code} ..."
        @stock.refresh_glasses
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

  def my_sleep
    seconds = 60 - Time.now.sec
    puts "#{@stock.stock_code}: going to sleep for #{seconds} seconds"
    sleep(seconds)
  end
end
