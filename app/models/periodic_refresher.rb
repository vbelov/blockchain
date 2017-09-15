class PeriodicRefresher
  def run
    counter = 0

    loop do
      my_sleep
      puts 'updating yobit ...'
      Stocks::Yobit.new.refresh_glasses
      counter += 1
      # break if counter == 1
    end
  end

  private

  def my_sleep
    seconds = 60 - Time.now.sec
    puts "going to sleep for #{seconds} seconds"
    sleep(seconds)
  end
end
