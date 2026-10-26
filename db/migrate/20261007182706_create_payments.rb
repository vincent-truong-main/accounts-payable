class CreatePayments < ActiveRecord::Migration[8.1]
  def change
    create_table :payments do |t|
      t.references :invoice, null: false, foreign_key: true
      t.integer :amount_cents, null: false
      t.date :paid_on, null: false
      t.string :payment_method, null: false, default: "ach"

      t.timestamps
    end
  end
end
