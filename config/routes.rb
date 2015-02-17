BioCatalogue::Application.routes.draw do

  #get "wms_service_layer/show"

  get "wms_service_layer/layer"

  get '/wms_service_layer/:id', to: 'wms_service_layer#show'

  get "wms_methods/update_resource_path"

  get "services/test"

  get "wms_methods/edit_resource_path_popup"

  get "wms_methods/update_endpoint_name"

  get "wms_methods/edit_endpoint_name_popup"

  get "wms_methods/update"

  get "wms_methods/edit_by_popup"

  get "wms_methods/remove_endpoint_name"

  get "wms_methods/inline_add_endpoint_name"

  get "wms_methods/index"

  get "wms_methods/filtered_index"

  get "wms_methods/show"

  get "wms_methods/inputs"

  get "wms_methods/outputs"

  get "wms_methods/annotations"

  get "wms_methods/destroy"

  get "wms_methods/edit_group_name_popup"

  get "wms_methods/update_group_name"

  get "wms_methods/group_name_auto_complete"

  get "wms_methods/filters"

  get "wms_methods/authorise"

  get "wms_methods/parse_sort_params"

  get "wms_methods/find_rest_method"

  get "wms_methods/find_rest_methods"

  get "wms_methods/destroy_unused_objects"

  get "wms_parameters/show"

  get "wms_parameters/annotations"

  get "wms_parameters/update_default_value"

  get "wms_parameters/edit_default_value_popup"

  get "wms_parameters/remove_default_value"

  get "wms_parameters/inline_add_default_value"

  get "wms_parameters/update_constrained_options"

  get "wms_parameters/edit_constrained_options_popup"

  get "wms_parameters/remove_constrained_options"

  get "wms_parameters/new_popup"

  get "wms_parameters/add_new_parameters"

  get "wms_parameters/localise_globalise_parameter"

  get "wms_parameters/make_optional_or_mandatory"

  get "wms_parameters/destroy"

  get "wms_parameters/authorise"

  get "wms_parameters/get_redirect_url"

  get "wms_parameters/destroy_method_param_map"

  get "wms_parameters/find_rest_parameter"

  get "wms_parameters/find_rest_method"

  get "wms_parameters/find_rest_methods"

  get "wms_representations/show"

  get "wms_representations/annotations"

  get "wms_representations/new_popup"

  get "wms_representations/add_new_representations"

  get "wms_representations/destroy"

  get "wms_representations/authorise"

  get "wms_representations/find_rest_method"

  get "wms_representations/find_rest_methods"

  get "wms_representations/find_rest_representation"

  get "wms_representations/get_redirect_url"

  get "wms_representations/destroy_method_rep_map"

  get "wms_resources/new_popup"

  get "wms_resources/add_new_resources"

  get "wms_resources/index"

  get "wms_resources/show"

  get "wms_resources/annotations"

  get "wms_resources/methods"

  get "wms_resources/parse_sort_params"

  get "wms_resources/authorise"

  get "wms_resources/find_wms_service"

  get "wms_resources/find_wms_resource"
=begin

  get "wms_services/new"

  get "wms_services/edit"

=end
 # get "wms_services/test"

  resources :oauth_clients

  match '/oauth/test_request' => 'oauth#test_request', :as => :test_request
  match '/oauth/access_token' => 'oauth#access_token', :as => :access_token
  match '/oauth/request_token' => 'oauth#request_token', :as => :request_token
  match '/oauth/authorize' => 'oauth#authorize', :as => :authorize
  match '/oauth' => 'oauth#index', :as => :oauth
  match '/curation' => 'curation#show', :as => :curation, :via => :get
  match '/curation/reports/potential_duplicate_operations_within_service' => 'curation#potential_duplicate_operations_within_service', :as => :curation_reports_potential_duplicate_operations_within_service, :via => :get
  match '/curation/reports/providers_without_services' => 'curation#providers_without_services', :as => :curation_reports_providers_without_services, :via => :get
  match '/curation/reports/services_missing_annotations' => 'curation#services_missing_annotations', :as => :curation_reports_services_missing_annotations, :via => [:get, :post]
  match '/curation/tools/copy_annotations' => 'curation#copy_annotations', :as => :curation_tools_copy_annotations, :via => [:get, :post]
  match '/curation/tools/copy_annotations_preview' => 'curation#copy_annotations_preview', :as => :curation_tools_copy_annotations_preview, :via => :post
  match '/curation/reports/annotation_level' => 'curation#annotation_level', :as => :curation_annotation_level, :via => :get
  match '/curation/reports/links_checker' => 'curation#links_checker', :as => :link_checker, :via => :get
  match '/curation/tools/download_latest_csv' => 'curation#download_latest_csv', :as => :download_latest_csv, :via => :get
  match '/curation/tools/csv_export' => 'curation#download_csv_page', :as => :download_csv_page, :via => :get

  match '/api.:format' => 'api#show', :as => :api
  match '/lookup.:format' => 'lookup#show', :as => :lookup
  match '/lookup' => 'lookup#show', :as => :lookup
=begin

  match '/wms_services/test' => 'wms_services#test'
=end

  resources :announcements

  resources :service_tests do

    member do
      get :results
      put :enable
      put :disable
      post :new_url_monitor_popup
      post :create_monitoring_endpoint
      post :edit_monitoring_endpoint_by_popup
      post :update_monitoring_endpoint
    end

  end

  resources :test_results

  resources :test_scripts do

    member do
      get :download
    end

  end

  match '/fail/:http_code' => 'fail#index', :as => :fail_page
  match '/stats' => 'stats#index', :as => :stats_index
  match '/stats/refresh' => 'stats#refresh', :as => :refresh_stats, :via => :post

  resources :stats do

    collection do
      get :general
      get :metadata
      get :tags
      get :search
    end
  end

  resources :categories do

    member do
      get :services
    end

  end

  resources :registries do

    member do
      get :annotations_by
      get :services
    end

  end

  resources :agents do

    member do
      get :annotations_by
    end

  end

  resources :annotations do

    collection do
      post :create_multiple
      post :new_popup
      post :create_inline
      post :filtered_index
      get :filters
      post :bulk_create
    end

    member do
      post :edit_popup
      post :promote_alternative_name
      get :download
    end

  end

  resources :annotation_attributes do

    member do
      get :annotations
    end

  end

  resources :tags, :only => [:index, :show, :destroy] do

    collection do
      delete :destroy_taggings
      post :auto_complete
    end


  end

  match '/search/auto_complete' => 'search#auto_complete', :as => :search_auto_complete, :via => :post
  match '/search/ignore_last' => 'search#ignore_last', :as => :ignore_last_search, :via => :post
  match '/search.:format' => 'search#show', :as => :search, :via => [:get, :post]
  match '/search' => 'search#show', :as => :search, :via => [:get, :post]
  match '/search/by_data.:format' => 'search#by_data', :as => :search_by_data, :via => [:get, :post]
  match '/search/by_data' => 'search#by_data', :as => :search_by_data, :via => [:post, :get]



  resources :service_providers do

    collection do
      post :filtered_index
      get :filters
      post :edit_by_popup
      post :auto_complete
    end

    member do
      get :annotations_by
      get :annotations
      get :services
      post :edit_by_popup
      put :upload_logo
      delete :remove_logo

      #for loading tab partials
      get :hostnames
      get :profile
      get :services
    end

  end

  resources :service_provider_hostnames do
    collection do
      post :reassign_provider_by_popup
      post :reassign_provider
    end
  end

  resources :service_deployments do

    member do
      get :annotations
      post :edit_location_by_popup
      post :update_location
    end

  end

  resources :users do

    collection do
      get :whoami
      get :activate_account
      post :filtered_index
      get :rpx_merge_setup
      get :filters
      post :rpx_merge
    end

    member do
      put :remove_curator
      get :annotations_by
      put :deactivate
      get :change_password
      post :change_password
      get :favourites
      get :rpx_update
      post :rpx_update
      put :activate
      get :services_responsible
      get :services_annotated
      get :services_submitted
      get :service_status_notifications
      get :service_status
      get :saved_searches
      get :services
      put :make_curator
    end

  end

  match '/termsofuse' => 'termsofuse#index'

  match '/session' => 'sessions#create', :as => :session, :via => :post

  if ENABLE_RPX
    match '/session/rpx_token' => 'sessions#rpx_token', :as => :session_rpx_token
  end

  match '/register' => 'users#new', :as => :register
  match '/signup' => 'users#new', :as => :signup
  match '/login' => 'sessions#new', :as => :login
  match '/signin' => 'sessions#new', :as => :signin
  match '/logout' => 'sessions#destroy', :as => :logout, :via => :delete
  match '/activate_account/:security_token' => 'users#activate_account', :as => :activate_account, :security_token => nil
  match '/forgot_password' => 'users#forgot_password', :as => :forgot_password
  match '/request_reset_password' => 'users#request_reset_password', :as => :request_reset_password
  match '/reset_password/:security_token' => 'users#reset_password', :as => :reset_password, :security_token => nil
  match '/contact' => 'contact#create', :as => :submit_feedback, :via => :post
  match '/contact' => 'contact#index', :as => :contact, :via => :get
  match '/' => 'home#index', :as => :home
  match '/index.:format' => 'home#index', :as => :activity_feed
  match '/status_changes.:format' => 'home#status_changes', :as => :status_changes_feed

  match '/latest' => 'latest#show', :as => :latest
  match 'service_providers/auto_complete' => 'service_providers#auto_complete', :as => :service_provider_auto_complete, :via => :post


  resources :latest do
    collection do
      get :activity
      get :monitoring
      get :contributors
      get :services
    end
  end

  resources :rest_services do

    member do
      get :methods
      get :annotations
      get :deployments
      get :resources
      post :edit_base_endpoint_by_popup
    end

    collection do
      post :update_base_endpoint
      get :edit_base_endpoint_by_popup
    end

  end
  
 resources :wms_services do

    collection do
      get :methods
      get :test
    end

  end

  resources :rest_resources do

    member do
      get :methods
      get :annotations
    end

    collection do
      post :new_popup
      post :add_new_resources
    end

  end

  resources :rest_methods do

    collection do
      post :filtered_index
      get :filters
    end

    member do
      post :update_group_name
      post :group_name_auto_complete
      get :inputs
      get :outputs
      get :annotations
      post :inline_add_endpoint_name
      post :edit_group_name_popup
      post :update_resource_path
      put :remove_endpoint_name
      post :edit_endpoint_name_popup
      post :edit_resource_path_popup
      post :update_endpoint_name
    end

  end

  resources :rest_parameters do

    member do
      get :annotations
      post :inline_add_default_value
      put :make_optional_or_mandatory
      post :update_constrained_options
      put :remove_default_value
      get :remove_constrained_options
      post :update_default_value
      post :edit_constrained_options_popup
      post :edit_default_value_popup
      get :localise_globalise_parameter
    end

    collection do
      get :add_new_parameters
      post :add_new_parameters
      post :new_popup
    end

  end

  resources :rest_method_parameters

  resources :rest_representations do

    member do
      get :annotations
    end

    collection do
      post :add_new_representations
      post :new_popup
    end

  end

  resources :rest_method_representations

  resources :soap_services do

    collection do
      post :load_wsdl
      get :load_wsdl
      get :bulk_new
      get :wsdl_locations
    end

    member do
      get :operations
      get :annotations
      get :latest_wsdl
      get :deployments
    end

  end

  resources :soap_operations do

    collection do
      post :filtered_index
      get :filters
    end

    member do
      get :inputs
      get :outputs
      get :annotations
    end

  end

  resources :soap_inputs do

    member do
      get :annotations
    end

  end

  resources :soap_outputs do

    member do
      get :annotations
    end

  end

  resources :soaplab_servers do
    collection do
      post :load_wsdl
    end


  end

  resources :services do

    collection do
      post :filtered_index
      get :filters
      get :bmb
    end

    member do
      post :unarchive
      post :unfavourite
      post :favourite
      get :variants
      get :monitoring
      get :examples
      get :activity
      get :summary
      post :archive
      get :annotations
      post :categorise
      get :deployments
      post :check_updates
      get :service_endpoint
      get :example_scripts
      get :example_data
      get :example_workflows
    end

  end

  resources :responsibility_requests do

    member do
      put :cancel
      get :turn_down
      put :approve
      put :deny
    end

  end

  resources :service_responsibles do

    member do
      put :deactivate
      put :activate
    end

  end

  resources :saved_searches

  # Routes for the favourites plugin
  resources :favourites
  # Old Rails 2 route for favourites:
  # Favourites.map_routes(map)

  # Routes for the annotations plugin
  resources :annotations do

    collection do
      get :filters
      post :new_popup, :create_inline, :filtered_index, :bulk_create
    end

    member do
      get :download
      post :edit_popup, :promote_alternative_name
    end
  end
  # Old Rails 2 route for annotations:
  # Annotations.map_routes(map,
  #                       { :new_popup => :post,
  #                         :create_inline => :post,
  #                         :filters => :get,
  #                         :filtered_index => :post,
  #                         :bulk_create => :post },
  #                       { :edit_popup => :post,
  #                         :download => :get,
  #                         :promote_alternative_name => :post })


  # Route to old metal "alive" now in app/controllers/alive_controller.rb
  match '/alive' => 'alive#index'

  # Replaced with root :to => 'home#index' as we use root_url and root_path in the code
  #match '/' => 'home#index'
  root :to => 'home#index'

  #match '/:controller(/:action(/:id))'
end

