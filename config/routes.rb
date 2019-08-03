Rails.application.routes.draw do
  resources :policies
  resources :companies
  resources :employees

  # get "file_uploads" => "inventory_upload#index", as: :hotel_upload
  # post "hotel_file_upload" => "inventory_upload#create", as: :hotel_file_upload

  resources :file_uploads

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
