class AddReceivedOnToInvoices < ActiveRecord::Migration[8.1]
  def change
    add_column :invoices, :received_on, :date
  end
end
