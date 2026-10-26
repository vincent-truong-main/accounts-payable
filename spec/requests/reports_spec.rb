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
  end
end
