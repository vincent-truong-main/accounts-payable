class CreateInvoices < ActiveRecord::Migration[8.1]
  def change
    create_table :invoices do |t|
      t.references :vendor, null: false, foreign_key: true
      t.string :number, null: false
      t.string :status, null: false, default: "draft"
      t.date :issued_on, null: false
      t.date :due_on
      t.text :notes

      t.timestamps
    end
    add_index :invoices, :number, unique: true
    add_index :invoices, :status
  end
end
