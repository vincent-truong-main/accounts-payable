class ReportsController < ApplicationController
  def aging
    as_of = params[:as_of].present? ? Date.iso8601(params[:as_of]) : Date.current
    @aging_report = AgingReport.new(as_of: as_of)
  end
end
