namespace :tmp do
  desc 'Creates arbitrage periods'
  task create_arbitrage_periods: :environment do
    CreateArbitragePeriods.new.run
  end
end
