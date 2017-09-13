class Order
  include Virtus.model

  attribute :vector, Vector
  attribute :rate, Float
  attribute :target_volume, Float
  attribute :cumulative_volume, Float
  attribute :used, Symbol # :full, :partial, :none

  delegate :target_currency, :base_currency, :action,
           to: :vector

  def base_volume
    rate * target_volume
  end
end
