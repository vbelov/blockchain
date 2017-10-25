class Currency < ApplicationRecord
  self.primary_key = :code

  has_many :stock_currencies, foreign_key: 'app_currency_code'

  scope :active, -> { where(active: true) }

  class << self
    def find_by_code(code)
      find_by(code: code.downcase)
    end

    def find_by_code!(code)
      find_by!(code: code.downcase)
    end

    def btc
      find_by_code 'btc'
    end
  end

  # noinspection RubyInstanceMethodNamingConvention
  def CODE
    code.upcase
  end

  def btc?
    code == 'btc'
  end
end
