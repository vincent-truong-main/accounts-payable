require "rails_helper"

RSpec.describe LineItem, type: :model do
  it { is_expected.to validate_presence_of(:description) }
  it { is_expected.to validate_numericality_of(:quantity).is_greater_than(0) }

  it "computes its own total" do
    expect(build(:line_item, quantity: 3, unit_price_cents: 1_250).total_cents).to eq(3_750)
  end
end
