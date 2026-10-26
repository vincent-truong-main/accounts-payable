require "rails_helper"

RSpec.describe "Payments", type: :request do
  describe "POST /invoices/:invoice_id/payments" do
    it "records a payment and redirects back to the invoice" do
      invoice = create(:invoice, :with_line_items)

      post invoice_payments_path(invoice), params: { payment: { amount: "25.00", paid_on: Date.current, payment_method: "check" } }

      expect(response).to redirect_to(invoice_path(invoice))
      expect(invoice.payments.last.amount_cents).to eq(2_500)
    end
  end
end
