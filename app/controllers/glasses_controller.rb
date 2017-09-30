class GlassesController < ApplicationController
  helper_method :target_currency, :base_currency,
                :action, :volume,
                :result,
                :pair_codes, :pair_code, :stock_pair,
                :stock

  def index
  end

  private

  def stock
    @stock ||= Stock.find_by_code(glass_params[:stock_name]) || Stock.yobit
  end

  def result
    @result ||= stock.process_vector(vector, volume)
  end

  def vector
    Vector.my_find(target_currency, base_currency, action)
  end

  def target_currency
    pair_code.split(' / ')[0].downcase
  end

  def base_currency
    pair_code.split(' / ')[1].downcase
  end

  def pair_codes
    stock.visible_pairs.map(&:slashed_code)
  end

  def pair_code
    find = ->(code) { pair_codes.find { |p| p == code } }
    find.(glass_params[:pair]) || find.('ETH / BTC') || pair_codes.first
  end

  def stock_pair
    stock.get_stock_pair(pair_code)
  end

  def actions
    %w(sell buy)
  end

  def action
    (actions.find { |a| a == glass_params[:action] } || 'sell').to_sym
  end

  def volume
    (glass_params[:volume].presence || 0.1).to_f
  end

  def glass_params
    params[:glass].presence || {}
  end
end
