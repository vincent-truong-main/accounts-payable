class VendorsController < ApplicationController
  def index
    @vendors = Vendor.order(:name)
  end

  def show
    @vendor = Vendor.find(params[:id])
    @invoices = @vendor.invoices.order(issued_on: :desc)
  end
end
