# Ledger – technical interview

A tiny accounts-payable app: **vendors** send us **invoices** made of **line items**, and we record **payments** against them. That's the whole domain.

## Stack

- Ruby 4.0 / Rails 8.1, PostgreSQL, server-rendered ERB (no JavaScript build step)
- RSpec + FactoryBot + shoulda-matchers
- RuboCop (`rubocop-rails-omakase`) and Brakeman, both run in CI

## Setup

You need Ruby 4.0.5 (see `.ruby-version`) and a running PostgreSQL. If you don't have Postgres locally:

```sh
docker compose up -d
export PGUSER=postgres PGPASSWORD=postgres
```

Then:

```sh
bin/setup          # bundle install, create + migrate + seed the database
bin/rails server   # http://localhost:3000
```

Useful commands:

```sh
bundle exec rspec   # tests
bin/rubocop         # lint
bin/brakeman        # security scan
bin/rails console
```

## Where things are

```
app/models/        Vendor, Invoice, LineItem, Payment  (all the business logic)
app/controllers/   invoices, payments, vendors
app/views/         ERB templates
db/seeds.rb        deterministic sample data (5 vendors, 60 invoices)
spec/              model + request specs
```

Money is stored as integer cents everywhere (`*_cents` columns). The UI formats it via `ApplicationHelper#money`.

## Business rules

These are the rules the AP team works by. The app is supposed to implement them.

- Each vendor has payment terms in days ("Net 30"). An invoice is **due** that many days after the date **we received it** (`received_on`), not the date the vendor issued it. Vendors often issue an invoice days before it reaches us, and we don't pay late because of their mail.
- A user can override the due date on a specific invoice. Once set, it stays set.
- An invoice is **open** while it is `sent` and has a balance due. `draft` invoices haven't been approved for payment yet; `void` invoices were rejected. Neither is money we owe.
- An invoice is **overdue** when it is open and today is past its due date. An invoice due today is not overdue.
- An invoice becomes `paid` when recorded payments cover its total. Partial payments are normal.

## The exercise

Work in a branch and open a pull request against `main` when you're done. Commit as you go so we can follow your thinking. **One commit will not be accepted**. Follow the conventional commits pattern.

### Part 1 – Bugs

This app has bugs. Some are obvious once you run it, some are not. Find and fix as many as you can. The existing test suite is a starting point, not a safety net.

We care more about *how* you find and fix them (reasoning, tests, commit messages) than about the raw count.

### Part 2 – Feature: AP aging report

Add an **accounts-payable aging report** at `GET /reports/aging`.

For every vendor with a non-zero outstanding balance, show how much is owed broken into buckets based on how far past due each invoice is:

| Current | 1–30 days | 31–60 days | 61–90 days | 90+ days | Total |
|---------|-----------|------------|------------|----------|-------|

Requirements:

- One row per vendor, plus a grand-total row.
- "Current" means not yet due. Buckets are measured against the invoice's `due_on`.
- Only invoices with an outstanding balance count. `paid`, `void`, and `draft` invoices are excluded.
- Accept an optional `as_of` date param (`/reports/aging?as_of=2026-09-30`); default to today.
- Add `.csv` support: `GET /reports/aging.csv` returns the same table as CSV. The AP team opens these in Excel.
- Link it from the nav.
- Request and/or model specs covering the bucketing logic, including an edge case or two of your choosing.

Keep the query count sane. Design it the way you would if it were going into production tomorrow.

### Part 3 – Notes

In your PR description, tell us:

- What you fixed and how you found each issue.
- The number of SQL queries the invoices index page makes after your changes, and how you measured it.
- Anything you noticed but chose not to fix, and why.
- What you'd do next with another day.

**Reminder** that you must email your interviewer when starting, and you will be timeboxed to 3 hours maximum, open a PR and email again when completed.
