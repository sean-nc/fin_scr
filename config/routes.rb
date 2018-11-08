Rails.application.routes.draw do
  root 'static_pages#about'
  get '/search', to: 'static_pages#search'
  get '/profiles', to: 'static_pages#profiles'
  resources :search_terms, except: :show
end
