class DownloadsController < ApplicationController
  helper_method :stock_codes, :stock,
                :pair_codes, :pair,
                :time_from_str, :time_to_str,
                :volume

  def index
  end

  def create
    filename = "#{pair.underscored_code}-#{stock.code}.xlsx"
    data = Extractor.rates_xlsx(stock, pair, time_from, time_to, volume)
    send_data(data, content_type: 'application/vnd.ms-excel', filename: filename)
  end

  private

  def pair_codes
    Pair.visible.map(&:slashed_code).sort
  end

  def pair
    Pair.find_by_code(params[:pair_code]) || Pair.visible.first
  end

  def stocks
    pair.visible_on_stocks
  end

  def stock_codes
    stocks.map(&:code)
  end

  def stock
    Stock.find_by_code(params[:stock_code]) || stocks.first
  end

  def time_from
    @time_from ||= Time.zone.parse(params[:time_from]) rescue 1.day.ago
  end

  def time_from_str
    time_from.strftime('%d.%m.%Y %H:%M')
  end

  def time_to
    @time_to ||= (Time.zone.parse(params[:time_to]) rescue Time.zone.now)
  end

  def time_to_str
    time_to.strftime('%d.%m.%Y %H:%M')
  end

  def volume
    0.1
  end
end
