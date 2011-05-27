Acs::Application.routes.draw do
  
  resources :requests do
    resources :access_requests
  end
  
  get "foo/index"

  get "terminated_users/index"

  get "terminated_users/show"

  get "terminated_users/edit"

  match "transfer/new" => 'transfer#new'

  match "transfer/create" => 'transfer#create'

  get "search/index"

  get "search/users"

  root :to => 'user_sessions#new'
  resources :access_requests do
    resources :notes
    member do
      post :manager_approval
      post :assign_request
      post :resource_owner_approval
      post :complete
      post :unassign
      post :cancel
    end
    collection do
      # post :select_permissions
      get :revoke
      post :revoke_access
      get :help_desk
    end
  end

  match 'access_requests/new/permissions' => 'access_requests#permissions', :as => 'new_permissions_access_requests'
  # TODO not sure if there is a way, but it would be nice to move the line below int the access_request resource block
  # wanted to use it for both access_requests/grant/permissions and access_requests/revoke/permissions
  # but not sure if current way things work this is the best idea
  match 'access_requests/:to_do/permissions' => 'access_requests#choose_permissions', :as => 'choose_permissions'

  get "dashboard/index"
  get "dashboard/test"
  match 'dashboard' => 'dashboard#index', :as => 'dashboard'
  match 'dashboard/auto_refresh' => 'dashboard#auto_refresh', :as => 'auto_refresh'
  
  resources :users do
    resources :requests
   end

  resource :user_session
  match 'search' => 'search#index', :as => 'search'
  match 'logout' => 'user_sessions#destroy', :as => 'logout'
  match 'login' => 'user_sessions#new', :as => 'login'

  match 'admin' => 'admin/resources#index', :as => 'admin'
  # TODO lighten up all the routes with explicit routes
  match 'admin/users/new/permissions' => 'admin/users#permissions', :as => 'new_permissions_admin_users'  
  
  resource :preferences
  
  resources :resources do
    resources :resource_groups
  end

  resources :resource_groups do
    resources :resources
  end

  resources :jobs do
    resources :users
  end

  resources :departments do
    resources :users
  end
    
  namespace :admin do
    resources :mailer_templates do
      member do
        get :edit_description
      end
    end
    resources :roles do
      resources :users
    end
    resources :locations do
      resources :departments
      resources :users
    end
    resources :departments do
      resources :users
    end
    resources :jobs do
      resources :users
      resources :change_logs, :only => :index
      post :activate
    end
    resources :resource_sections
    resources :resource_groups do
      resources :resources
      resources :permission_types
    end
    resources :resources do
      post :activate
    end
    resources :terminated_users do
      member do
        post :rehire
      end
    end
    resources :users do
      member do
        get :review_permissions
        post :set_permissions
        post :terminate
        post :reactivate
        post :hr_confirm
        post :hr_veto
      end
      collection do
        get :import
        post :upload
        get :summary
      end
    end
    resources :employment_types do
      resources :users
    end
    # match 'change_log' => 'change_log/index'
    resources :change_logs, :only => :index
    resources :companies do
      resources :departments
      resources :users
    end
  end
end

