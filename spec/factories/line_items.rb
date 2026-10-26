FactoryBot.define do
  factory :line_item do
    invoice
    description { "Widget" }
    quantity { 1 }
    unit_price_cents { 1_000 }
  end
end
