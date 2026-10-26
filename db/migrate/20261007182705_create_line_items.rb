class CreateLineItems < ActiveRecord::Migration[8.1]
  def change
    create_table :line_items do |t|
      t.references :invoice, null: false, foreign_key: true
      t.string :description, null: false
      t.integer :quantity, null: false, default: 1
      t.integer :unit_price_cents, null: false, default: 0

      t.timestamps
    end
  end
end
