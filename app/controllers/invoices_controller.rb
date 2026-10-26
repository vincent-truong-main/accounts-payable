class InvoicesController < ApplicationController
  def index
    @invoices = Invoice.includes(:vendor, :line_items, :payments).order(issued_on: :desc)
    @invoices = @invoices.where(status: params[:status]) if params[:status].present?
    @invoices = @invoices.overdue if params[:overdue].present?
    @invoices = @invoices.where("number ILIKE ?", "%#{Invoice.sanitize_sql_like(params[:q])}%") if params[:q].present?
  end

  def show
    @invoice = Invoice.find(params[:id])
    @payment = Payment.new(invoice: @invoice, paid_on: Date.current)
  end

  def new
    @invoice = Invoice.new(issued_on: Date.current, received_on: Date.current)
    3.times { @invoice.line_items.build }
  end

  def create
    @invoice = Invoice.new(invoice_params)
    @invoice.status = "sent"

    if @invoice.save
      redirect_to @invoice, notice: "Invoice #{@invoice.number} created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def invoice_params
    params.require(:invoice).permit(
      :vendor_id, :number, :issued_on, :received_on, :due_on, :notes,
      line_items_attributes: %i[description quantity unit_price_cents]
    )
  end
end
