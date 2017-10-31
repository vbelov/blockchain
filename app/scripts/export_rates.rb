class ExportRates
  def run
    pairs = Pair.visible.sort_by(&:slashed_code)
    # pairs = [Pair.find_by_code('GNO / BTC')]
    pairs.each_with_index do |pair, pair_index|
      puts "[#{pair_index + 1} / #{pairs.count}] processing pair #{pair.slashed_code}"

      stocks = pair.visible_on_stocks.sort_by(&:code)
      stocks.each_with_index do |stock, stock_index|
        puts "  [#{stock_index + 1} / #{stocks.count}] processing stock #{stock.code}"

        time_from = 1.year.ago
        time_to = Time.now
        volume = 0.1
        data = Extractor.rates_xlsx(stock, pair, time_from, time_to, volume, include_chart: false)

        dir = File.join('tmp', 'export', pair.underscored_code)
        path = File.join(dir, "#{stock.code}.xlsx")
        FileUtils.mkpath(dir)
        File.open(path, 'w') { |f| f.write(data) }
      end
    end

    true
  end
end
