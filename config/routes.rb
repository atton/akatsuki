Rails.application.routes.draw do
  scope '/', controller: :home do
    get  :index
    post :new_session
    get  :sign_in
    get  :sign_out
  end

  resources :ip_addresses, except: [:index] do
    resource :virtual_machine, only: [:show, :destroy] do
      post :power_on
      post :power_off
    end
  end
  resource :virtual_machine, only: [:new, :create]

  namespace :ldap do
    resource :user, only: [:new, :create, :edit, :update]
  end

  namespace :admin do
    resources :local_records, except: :show
  end

  namespace :syskan do
    resources :users, only: :index do
      post :increment_vm_limit
      post :decrement_vm_limit
    end
    resources :virtual_machines, only: :index do
      post :toggle_cleanup_marked
    end
    resources :vlan51_ip_addresses, only: [:index, :new, :create, :destroy]
  end

  root to: 'home#index'

  get '*path', to: 'home#index'
end
