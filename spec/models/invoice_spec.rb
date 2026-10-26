require "rails_helper"

RSpec.describe Invoice, type: :model do
  it { is_expected.to belong_to(:vendor) }
  it { is_expected.to have_many(:line_items).dependent(:destroy) }
  it { is_expected.to have_many(:payments).dependent(:destroy) }
  it { is_expected.to validate_inclusion_of(:status).in_array(Invoice::STATUSES) }

  describe "#total_cents" do
    it "is the sum of quantity times unit price for every line item" do
      invoice = build(:invoice, :with_line_items)

      # 2 x $50.00 + 1 x $25.00
      expect(invoice.total_cents).to eq(12_500)
    end
  end

  describe "#balance_due_cents" do
    it "subtracts payments from the total" do
      invoice = create(:invoice, :with_line_items)
      create(:payment, invoice: invoice, amount_cents: 2_500)

      expect(invoice.balance_due_cents).to eq(invoice.total_cents - 2_500)
    end
  end

  describe "due date" do
    it "defaults due_on from the vendor's payment terms" do
      vendor = create(:vendor, payment_terms_days: 45)
      invoice = create(:invoice, vendor: vendor, issued_on: Date.new(2026, 1, 1))

      expect(invoice.due_on).to eq(Date.new(2026, 2, 15))
    end

    it "is due the vendor's payment terms after we received it, not after the vendor issued it" do
      vendor = create(:vendor, payment_terms_days: 30)
      invoice = create(:invoice, vendor: vendor, issued_on: Date.new(2026, 1, 1), received_on: Date.new(2026, 1, 10))

      expect(invoice.due_on).to eq(Date.new(2026, 2, 9))
    end

    it "keeps a user's due date override" do
      invoice = create(:invoice, due_on: Date.new(2026, 3, 1))

      expect(invoice.due_on).to eq(Date.new(2026, 3, 1))
    end

    it "keeps a due date override once set, even when the invoice is saved again" do
      invoice = create(:invoice, due_on: Date.new(2026, 3, 1))

      invoice.update!(notes: "Called vendor")

      expect(invoice.reload.due_on).to eq(Date.new(2026, 3, 1))
    end
  end

  describe "#overdue?" do
    it "is true for an unpaid invoice past its due date" do
      invoice = create(:invoice, issued_on: Date.current - 60.days)
      expect(invoice).to be_overdue
    end

    it "is false for a paid invoice" do
      invoice = create(:invoice, status: "paid", issued_on: Date.current - 60.days)
      expect(invoice).not_to be_overdue
    end
  end

  describe ".overdue" do
    it "includes unpaid invoices past their due date" do
      overdue = create(:invoice, issued_on: Date.current - 60.days)
      current = create(:invoice, issued_on: Date.current)

      expect(Invoice.overdue).to include(overdue)
      expect(Invoice.overdue).not_to include(current)
    end

    it "does not treat a draft invoice as overdue, because it hasn't been approved for payment yet" do
      draft_invoice = create(:invoice, status: "draft", due_on: Date.current - 1.day)

      expect(Invoice.overdue).not_to include(draft_invoice)
      expect(draft_invoice).not_to be_overdue
    end

    it "does not treat a void invoice as overdue, because it was rejected and isn't money we owe" do
      void_invoice = create(:invoice, status: "void", due_on: Date.current - 1.day)

      expect(Invoice.overdue).not_to include(void_invoice)
      expect(void_invoice).not_to be_overdue
    end

    it "does not treat an invoice due today as overdue" do
      invoice_due_today = create(:invoice, due_on: Date.current)

      expect(Invoice.overdue).not_to include(invoice_due_today)
      expect(invoice_due_today).not_to be_overdue
    end
  end

  describe "#record_payment!" do
    it "creates a payment" do
      invoice = create(:invoice, :with_line_items)

      expect {
        invoice.record_payment!(amount_cents: 1_000, paid_on: Date.current)
      }.to change(invoice.payments, :count).by(1)
    end

    it "settles the invoice when the payment covers the total" do
      invoice = create(:invoice, :with_line_items)

      invoice.record_payment!(amount_cents: invoice.total_cents, paid_on: Date.current)

      expect(invoice.reload.balance_due_cents).to eq(0)
      expect(invoice.status).to eq("paid")
      expect(invoice).not_to be_overdue
    end

    it "rejects a payment larger than the balance due" do
      invoice = create(:invoice, :with_line_items)

      expect {
        invoice.record_payment!(amount_cents: invoice.total_cents + 1_000, paid_on: Date.current)
      }.to raise_error(Invoice::Overpayment)
    end

    it "leaves a partially paid invoice open" do
      invoice = create(:invoice, :with_line_items)

      invoice.record_payment!(amount_cents: 100, paid_on: Date.current)

      expect(invoice.reload.status).to eq("sent")
    end
  end
end
