require "rails_helper"

RSpec.describe "Invoices", type: :request do
  describe "GET /invoices" do
    it "lists invoices" do
      invoice = create(:invoice, :with_line_items)

      get invoices_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(invoice.number)
    end

    it "filters by status" do
      sent = create(:invoice, status: "sent")
      paid = create(:invoice, status: "paid")

      get invoices_path(status: "paid")

      expect(response.body).to include(paid.number)
      expect(response.body).not_to include(sent.number)
    end
  end

  describe "GET /invoices/:id" do
    it "shows the invoice" do
      invoice = create(:invoice, :with_line_items)

      get invoice_path(invoice)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Balance due")
    end
  end

  describe "POST /invoices" do
    it "creates an invoice with line items" do
      vendor = create(:vendor)

      expect {
        post invoices_path, params: {
          invoice: {
            vendor_id: vendor.id, number: "INV-9001", issued_on: Date.current, received_on: Date.current,
            line_items_attributes: { "0" => { description: "Thing", quantity: 2, unit_price_cents: 100 } }
          }
        }
      }.to change(Invoice, :count).by(1)

      expect(response).to redirect_to(invoice_path(Invoice.last))
    end

    it "ignores untouched blank line item rows from the form" do
      vendor = create(:vendor)

      post invoices_path, params: {
        invoice: {
          vendor_id: vendor.id, number: "INV-9002", issued_on: Date.current, received_on: Date.current,
          line_items_attributes: {
            "0" => { description: "Thing", quantity: 2, unit_price_cents: 100 },
            "1" => { description: "", quantity: 1, unit_price_cents: "" },
            "2" => { description: "", quantity: 1, unit_price_cents: "" }
          }
        }
      }

      expect(Invoice.last.line_items.count).to eq(1)
    end
  end
end
