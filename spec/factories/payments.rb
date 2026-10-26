FactoryBot.define do
  factory :payment do
    invoice
    amount_cents { 1_000 }
    paid_on { Date.current }
    payment_method { "ach" }
  end
end
