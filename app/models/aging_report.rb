# How much we owe each vendor as of a date, broken into buckets by how far
# past due each open invoice is.
class AgingReport
  BUCKETS = %i[current days_1_30 days_31_60 days_61_90 days_over_90].freeze

  VendorRow = Data.define(:vendor, :outstanding_balance_by_bucket, :total_cents)

  attr_reader :as_of

  def initialize(as_of:)
    @as_of = as_of
  end

  def vendor_rows
    open_invoices.group_by(&:vendor).map do |vendor, invoices|
      outstanding_balance_by_bucket = BUCKETS.index_with(0)

      invoices.each do |invoice|
        outstanding_balance_by_bucket[aging_bucket(invoice)] += invoice.balance_due_cents
      end

      VendorRow.new(
        vendor: vendor,
        outstanding_balance_by_bucket: outstanding_balance_by_bucket,
        total_cents: invoices.sum(&:balance_due_cents)
      )
    end.sort_by { |row| row.vendor.name }
  end

  private

  def open_invoices
    Invoice.open.includes(:vendor, :line_items, :payments)
  end

  # Current means not yet due; an invoice due on the as-of date isn't past due.
  def aging_bucket(invoice)
    case (as_of - invoice.due_on).to_i
    when ..0 then :current
    when 1..30 then :days_1_30
    when 31..60 then :days_31_60
    when 61..90 then :days_61_90
    else :days_over_90
    end
  end
end
