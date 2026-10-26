module ApplicationHelper
  def money(cents)
    number_to_currency(cents.to_i / 100.0)
  end

  def status_badge(status)
    tag.span(status.titleize, class: "badge badge-#{status}")
  end
end
