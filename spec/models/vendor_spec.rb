require "rails_helper"

RSpec.describe Vendor, type: :model do
  it { is_expected.to have_many(:invoices).dependent(:destroy) }
  it { is_expected.to validate_presence_of(:name) }

  describe "#outstanding_balance_cents" do
    it "sums the balance due across the vendor's invoices" do
      vendor = create(:vendor)
      create(:invoice, :with_line_items, vendor: vendor)
      create(:invoice, :with_line_items, vendor: vendor)

      expect(vendor.outstanding_balance_cents).to be > 0
    end
  end
end
