class GlassesController < ApplicationController
  helper_method :target_currency, :base_currency,
                :action, :volume,
                :result,
                :valid_pairs, :pair,
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
    pair.split(' / ')[0].downcase
  end

  def base_currency
    pair.split(' / ')[1].downcase
  end

  def valid_pairs
    stock.valid_pairs.map(&:slashed_code)
  end

  def pair
    find = ->(code) { valid_pairs.find { |p| p == code } }
    find.(glass_params[:pair]) || find.('ETH / BTC') || valid_pairs.first
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
