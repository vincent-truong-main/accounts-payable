# How much we owe each vendor as of a date, broken into buckets by how far
# past due each open invoice is.
class AgingReport
  BUCKETS = %i[current days_1_30 days_31_60 days_61_90 days_over_90].freeze
  COLUMN_HEADERS = [ "Vendor", "Current", "1–30 days", "31–60 days", "61–90 days", "90+ days", "Total" ].freeze

  # Excel runs a cell starting with one of these as a formula.
  FORMULA_TRIGGERS = [ "=", "+", "-", "@", "\t", "\r" ].freeze

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

  def to_csv
    CSV.generate do |csv|
      csv << COLUMN_HEADERS
      vendor_rows.each do |row|
        amounts = BUCKETS.map { |bucket| row.outstanding_balance_by_bucket[bucket] } + [ row.total_cents ]
        csv << [ excel_safe_text(row.vendor.name), *amounts.map { |cents| csv_amount(cents) } ]
      end
    end
  end

  private

  # Prefix with a quote so Excel shows the text instead of running it.
  def excel_safe_text(text)
    text.start_with?(*FORMULA_TRIGGERS) ? "'#{text}" : text
  end

  # Plain decimal dollars so Excel treats the cell as a number.
  def csv_amount(cents)
    format("%d.%02d", *cents.divmod(100))
  end

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
