class GlassesController < ApplicationController
  helper_method :pair, :target_currency, :base_currency, :action, :volume, :result, :valid_pairs

  def index
  end

  private

  def yobit
    @yobit ||= Stocks::Yobit.new
  end

  def result
    @result ||= yobit.process_glass(target_currency, base_currency, action, volume)
  end

  def target_currency
    pair.split(' / ')[0].downcase
  end

  def base_currency
    pair.split(' / ')[1].downcase
  end

  def valid_pairs
    yobit.valid_pairs.map { |p| p.split('_').map(&:upcase).join(' / ') }
  end

  def pair
    valid_pairs.find { |p| p == glass_params[:pair] } || 'ETH / BTC'
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
