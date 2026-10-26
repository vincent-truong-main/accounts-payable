FactoryBot.define do
  factory :vendor do
    sequence(:name) { |n| "Vendor #{n}" }
    sequence(:email) { |n| "ap#{n}@vendor.example" }
    payment_terms_days { 30 }
  end
end
