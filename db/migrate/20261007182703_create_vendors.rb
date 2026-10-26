class CreateVendors < ActiveRecord::Migration[8.1]
  def change
    create_table :vendors do |t|
      t.string :name, null: false
      t.string :email
      t.integer :payment_terms_days, null: false, default: 30

      t.timestamps
    end
    add_index :vendors, :name, unique: true
  end
end
