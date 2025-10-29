FactCheck::Engine.routes.draw do
  root to: "publications#index"
  resources :publications
end
