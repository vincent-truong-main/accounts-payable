# How much we owe each vendor as of a date, from their open invoices.
class AgingReport
  attr_reader :as_of

  def initialize(as_of:)
    @as_of = as_of
  end

  def outstanding_balance_by_vendor
    Invoice.open.includes(:vendor, :line_items, :payments)
      .group_by(&:vendor)
      .transform_values { |invoices| invoices.sum(&:balance_due_cents) }
  end
end
