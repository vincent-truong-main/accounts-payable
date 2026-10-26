FactoryBot.define do
  factory :invoice do
    vendor
    sequence(:number) { |n| "INV-#{1000 + n}" }
    status { "sent" }
    issued_on { Date.current - 10.days }
    received_on { issued_on }

    trait :with_line_items do
      after(:build) do |invoice|
        invoice.line_items << build(:line_item, invoice: invoice, quantity: 2, unit_price_cents: 5_000)
        invoice.line_items << build(:line_item, invoice: invoice, quantity: 1, unit_price_cents: 2_500)
      end
    end
  end
end
