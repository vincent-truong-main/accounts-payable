class ReportsController < ApplicationController
  def aging
    as_of = params[:as_of].present? ? Date.iso8601(params[:as_of]) : Date.current
    @aging_report = AgingReport.new(as_of: as_of)

    respond_to do |format|
      format.html
      format.csv { send_data @aging_report.to_csv, filename: "ap-aging-#{as_of}.csv", type: :csv }
    end
  end
end
