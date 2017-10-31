desc 'Export rates for all stocks and all pairs'
task export_rates: :environment do
  ExportRates.new.run
end
