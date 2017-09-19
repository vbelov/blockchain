namespace :tmp do
  desc 'Fills time in glasses'
  task fill_time_in_glasses: :environment do
    FillTimeInGlasses.new.run
  end
end
