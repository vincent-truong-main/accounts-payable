class Payment < ApplicationRecord
  METHODS = %w[ach check card wire].freeze

  belongs_to :invoice

  validates :paid_on, presence: true
  validates :payment_method, inclusion: { in: METHODS }
end
