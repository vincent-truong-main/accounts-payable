require "rails_helper"

RSpec.describe "AP aging report", type: :request do
  describe "GET /reports/aging" do
    it "shows how much we owe each vendor as of the given date" do
      vendor = create(:vendor, name: "Acme Supplies")
      invoice = create(:invoice, vendor: vendor, due_on: Date.new(2026, 9, 15))
      create(:line_item, invoice: invoice, quantity: 1, unit_price_cents: 10_000)

      get aging_report_path(as_of: "2026-09-30")

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Acme Supplies")
      expect(response.body).to include("$100.00")
    end

    it "is linked from the nav" do
      get invoices_path

      expect(response.body).to include(%(href="#{aging_report_path}"))
    end

    it "exports the same table as CSV for Excel" do
      vendor = create(:vendor, name: "Acme Supplies")
      invoice = create(:invoice, vendor: vendor, due_on: Date.new(2026, 9, 15))
      create(:line_item, invoice: invoice, quantity: 1, unit_price_cents: 10_000)

      get aging_report_path(format: :csv, as_of: "2026-09-30")

      csv = CSV.parse(response.body)
      expect(response.media_type).to eq("text/csv")
      expect(csv.first).to eq([ "Vendor", "Current", "1–30 days", "31–60 days", "61–90 days", "90+ days", "Total" ])
      expect(csv.second).to eq([ "Acme Supplies", "0.00", "100.00", "0.00", "0.00", "0.00", "100.00" ])
    end

    it "stops Excel from running a vendor name as a formula" do
      vendor = create(:vendor, name: "@Home Services LLC")
      invoice = create(:invoice, vendor: vendor)
      create(:line_item, invoice: invoice, quantity: 1, unit_price_cents: 10_000)

      get aging_report_path(format: :csv)

      expect(CSV.parse(response.body).second.first).to eq("'@Home Services LLC")
    end
  end
end
