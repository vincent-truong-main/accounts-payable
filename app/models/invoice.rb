class Invoice < ApplicationRecord
  STATUSES = %w[draft sent paid void].freeze

  belongs_to :vendor
  has_many :line_items, dependent: :destroy
  has_many :payments, dependent: :destroy
  accepts_nested_attributes_for :line_items,
    reject_if: ->(attrs) { attrs["description"].blank? && attrs["unit_price_cents"].blank? }

  validates :number, presence: true, uniqueness: true
  validates :status, inclusion: { in: STATUSES }
  validates :issued_on, :received_on, presence: true

  before_validation :set_due_on

  scope :open, -> { where(status: %w[sent]) }
  # Sent invoices whose due date has passed. An invoice due today is not overdue.
  scope :overdue, -> { where(status: "sent").where("due_on < ?", Date.current) }

  def total_cents
    line_items.sum { |li| li.total_cents }
  end

  def paid_cents
    payments.sum(&:amount_cents)
  end

  def balance_due_cents
    total_cents - paid_cents
  end

  def overdue?
    status == "sent" && due_on.present? && due_on < Date.current
  end

  class Overpayment < StandardError; end

  def record_payment!(amount_cents:, paid_on:, method: "ach")
    raise Overpayment, "Payment exceeds balance due" if amount_cents > balance_due_cents

    transaction do
      payments.create!(amount_cents: amount_cents, paid_on: paid_on, payment_method: method)
      update!(status: "paid") if balance_due_cents <= 0
    end
  end

  private

  def set_due_on
    return if received_on.blank? || vendor.blank?

    self.due_on ||= received_on + vendor.payment_terms_days.days
  end
end
