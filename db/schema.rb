# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_10_13_120000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "invoices", force: :cascade do |t|
    t.bigint "vendor_id", null: false
    t.string "number", null: false
    t.string "status", default: "draft", null: false
    t.date "issued_on", null: false
    t.date "due_on"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "received_on"
    t.index ["number"], name: "index_invoices_on_number", unique: true
    t.index ["status"], name: "index_invoices_on_status"
    t.index ["vendor_id"], name: "index_invoices_on_vendor_id"
  end

  create_table "line_items", force: :cascade do |t|
    t.bigint "invoice_id", null: false
    t.string "description", null: false
    t.integer "quantity", default: 1, null: false
    t.integer "unit_price_cents", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["invoice_id"], name: "index_line_items_on_invoice_id"
  end

  create_table "payments", force: :cascade do |t|
    t.bigint "invoice_id", null: false
    t.integer "amount_cents", null: false
    t.date "paid_on", null: false
    t.string "payment_method", default: "ach", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["invoice_id"], name: "index_payments_on_invoice_id"
  end

  create_table "vendors", force: :cascade do |t|
    t.string "name", null: false
    t.string "email"
    t.integer "payment_terms_days", default: 30, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_vendors_on_name", unique: true
  end

  add_foreign_key "invoices", "vendors"
  add_foreign_key "line_items", "invoices"
  add_foreign_key "payments", "invoices"
end
