require "rails_helper"

RSpec.describe AgingReport do
  describe "aging buckets" do
    let(:as_of) { Date.new(2026, 9, 30) }

    def aging_bucket_for(days_past_due:)
      invoice = create(:invoice, due_on: as_of - days_past_due)
      create(:line_item, invoice: invoice, quantity: 1, unit_price_cents: 10_000)
      vendor_row = AgingReport.new(as_of: as_of).vendor_rows.first
      vendor_row.outstanding_balance_by_bucket.select { |_bucket, cents| cents.positive? }.keys
    end

    it "ages an invoice due on the as-of date as Current" do
      expect(aging_bucket_for(days_past_due: 0)).to eq([ :current ])
    end

    it "ages an invoice 1 day past due into 1–30 days" do
      expect(aging_bucket_for(days_past_due: 1)).to eq([ :days_1_30 ])
    end

    it "ages an invoice 30 days past due into 1–30 days" do
      expect(aging_bucket_for(days_past_due: 30)).to eq([ :days_1_30 ])
    end

    it "ages an invoice 31 days past due into 31–60 days" do
      expect(aging_bucket_for(days_past_due: 31)).to eq([ :days_31_60 ])
    end

    it "ages an invoice 60 days past due into 31–60 days" do
      expect(aging_bucket_for(days_past_due: 60)).to eq([ :days_31_60 ])
    end

    it "ages an invoice 61 days past due into 61–90 days" do
      expect(aging_bucket_for(days_past_due: 61)).to eq([ :days_61_90 ])
    end

    it "ages an invoice 90 days past due into 61–90 days" do
      expect(aging_bucket_for(days_past_due: 90)).to eq([ :days_61_90 ])
    end

    it "ages an invoice 91 days past due into 90+ days" do
      expect(aging_bucket_for(days_past_due: 91)).to eq([ :days_over_90 ])
    end

    it "ages an invoice with no due date from when we received it plus the vendor's payment terms" do
      vendor = create(:vendor, payment_terms_days: 30)
      invoice = create(:invoice, vendor: vendor, received_on: as_of - 40.days)
      invoice.update_column(:due_on, nil)
      create(:line_item, invoice: invoice, quantity: 1, unit_price_cents: 10_000)

      vendor_row = AgingReport.new(as_of: as_of).vendor_rows.first

      expect(vendor_row.outstanding_balance_by_bucket[:days_1_30]).to eq(10_000)
    end
  end
end
