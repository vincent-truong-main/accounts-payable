# Deterministic seed data so every candidate sees the same ledger.
srand(42)

Payment.delete_all
LineItem.delete_all
Invoice.delete_all
Vendor.delete_all

vendors = [
  [ "Acme Concrete Supply", "ap@acmeconcrete.example", 30 ],
  [ "Blue Ridge Electrical", "billing@blueridge.example", 45 ],
  [ "Cascade Plumbing Co.", "invoices@cascadeplumbing.example", 15 ],
  [ "Delta Steel Fabricators", "ar@deltasteel.example", 60 ],
  [ "Evergreen Landscaping", "hello@evergreen.example", 30 ],
  [ "@Home Services LLC", "billing@athomeservices.example", 15 ]
].map { |name, email, terms| Vendor.create!(name: name, email: email, payment_terms_days: terms) }

descriptions = [
  "Ready-mix concrete (yd)", "Rebar #4 (ton)", "Conduit 3/4in (ft)", "Panel install labor (hr)",
  "Copper pipe 1in (ft)", "Fixture install (ea)", "Structural beam W12 (ea)", "Weld inspection (hr)",
  "Sod (pallet)", "Irrigation controller (ea)", "Equipment rental (day)", "Delivery fee"
]

today = Date.current
invoice_counter = 1000

60.times do |i|
  vendor = vendors[i % vendors.size]
  issued_on = today - rand(5..120).days
  status = %w[sent sent sent paid paid void draft].sample

  invoice = Invoice.new(
    vendor: vendor,
    number: "INV-#{invoice_counter += 1}",
    status: status,
    issued_on: issued_on,
    received_on: issued_on + rand(0..6).days,
    notes: (rand < 0.3 ? "PO ##{rand(10_000..99_999)}" : nil)
  )
  invoice.line_items.build(
    (1..rand(1..4)).map do
      { description: descriptions.sample, quantity: rand(1..12), unit_price_cents: rand(1_500..85_000) }
    end
  )
  invoice.save!
  # Drafts haven't been approved yet, so they have no due date. A handful of
  # older sent invoices came over from the previous system without one either.
  invoice.update_column(:due_on, nil) if status == "draft" || (status == "sent" && i % 23 == 5)
  invoice.update_column(:due_on, today) if i == 7

  total = invoice.line_items.sum(&:total_cents)
  case status
  when "paid"
    invoice.payments.create!(amount_cents: total, paid_on: issued_on + rand(3..40).days, payment_method: Payment::METHODS.sample)
  when "sent"
    if rand < 0.4
      # Partial payments; the AP team sometimes keys the check amount off the PO rather than the invoice.
      invoice.payments.create!(amount_cents: (total * rand(0.25..1.15)).round, paid_on: issued_on + rand(3..20).days, payment_method: "check")
    end
  end
end

puts "Seeded #{Vendor.count} vendors, #{Invoice.count} invoices, #{LineItem.count} line items, #{Payment.count} payments."
