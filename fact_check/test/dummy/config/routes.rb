Rails.application.routes.draw do
  mount FactCheck::Engine => "/fact_check"
end
