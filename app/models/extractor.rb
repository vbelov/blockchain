class Extractor
  def self.rates_xlsx(stock, pair, time_from, time_to, volume)
    doc = Axlsx::Package.new do |excel_doc|
      excel_doc.workbook do |wb|
        title = wb.styles.add_style(b: true)
        time_style = wb.styles.add_style(format_code: 'yyyy-mm-dd hh:mm:ss')
        wb.add_worksheet(name: "#{stock.code} #{pair.underscored_code} rates") do |sheet|
          sheet.add_row %w(Время Покупка Продажа Timestamp), style: title

          glasses = Glass.where(
              stock_code: stock.code,
              target_code: pair.target_code,
              base_code: pair.base_code,
              time: (time_from..time_to),
          ).order(:time).to_a

          glasses.each do |glass|
            buy_rate = stock.process_glass_fast(glass, :buy, volume)
            sell_rate = stock.process_glass_fast(glass, :sell, volume)
            row = [glass.time, buy_rate, sell_rate, glass.time.to_i]
            sheet.add_row(row, style: [time_style, nil, nil, nil])
          end

          rows = glasses.count
          sheet.add_chart(Axlsx::LineChart, title: 'График колебания курса', rotX: 30, rotY: 20) do |chart|
            chart.start_at 3, 1
            chart.end_at 20, 30
            chart.add_series data: sheet["B2:B#{rows}"],
                             labels: sheet["D2:D#{rows}"],
                             title: sheet['B1'],
                             color: '009900',
                             show_marker: false,
                             smooth: false
            chart.add_series data: sheet["C2:C#{rows}"],
                             labels: sheet["D2:D#{rows}"],
                             title: sheet['C1'],
                             color: '333399',
                             show_marker: false,
                             smooth: false
            chart.catAxis.tick_lbl_skip = 100
            chart.catAxis.tick_mark_skip = 20
            chart.catAxis.title = 'Время'
            chart.valAxis.title = 'Курс'
          end

          # fields.each_with_index do |name, column_index|
          #   sheet.column_info[column_index].width.to_i > 18 ? sheet.column_info[column_index].width = 18 : nil
          # end
        end
      end
    end

    doc.to_stream.read
  end
end
