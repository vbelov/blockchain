class PeriodicRefresher
  def run
    counter = 0
    pool = Concurrent::FixedThreadPool.new(5) # 5 threads

    loop do
      begin
        my_sleep

        Stock.all.each do |stock|
          pool.post do
            begin
              puts "updating #{stock.stock_code} ..."
              Rails.application.executor.wrap do
                stock.refresh_glasses
              end
            rescue => err
              puts '===================  ERROR  ===================='
              puts err.message
              err.backtrace.each { |l| puts l }
            end
          end
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

  def my_sleep
    seconds = 60 - Time.now.sec
    puts "going to sleep for #{seconds} seconds"
    sleep(seconds)
  end
end
