namespace :tmp do
  desc 'Removes extra data from glasses'
  task meliorate_glasses: :environment do
    MeliorateGlasses.new.run
  end
end
