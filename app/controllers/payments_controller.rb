class PaymentsController < ApplicationController
  def create
    invoice = Invoice.find(params[:invoice_id])
    amount_cents = (params[:payment][:amount].to_f * 100).to_i

    invoice.record_payment!(
      amount_cents: amount_cents,
      paid_on: params[:payment][:paid_on],
      method: params[:payment][:payment_method]
    )

    redirect_to invoice, notice: "Payment recorded."
  rescue ActiveRecord::RecordInvalid, Invoice::Overpayment => e
    redirect_to invoice, alert: e.message
  end
end
