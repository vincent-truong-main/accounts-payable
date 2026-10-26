class Vendor < ApplicationRecord
  has_many :invoices, dependent: :destroy

  validates :name, presence: true, uniqueness: true
  validates :payment_terms_days, numericality: { greater_than_or_equal_to: 0 }

  # Total amount still owed to this vendor across all invoices.
  def outstanding_balance_cents
    invoices.sum(&:balance_due_cents)
  end
end
