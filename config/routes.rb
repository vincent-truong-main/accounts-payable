Rails.application.routes.draw do
  root "invoices#index"

  resources :vendors, only: %i[index show]
  resources :invoices, only: %i[index show new create] do
    resources :payments, only: :create
  end

  get "reports/aging", to: "reports#aging", as: :aging_report

  get "up" => "rails/health#show", as: :rails_health_check
end
