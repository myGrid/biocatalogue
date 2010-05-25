# BioCatalogue: app/config/routes.rb
#
# Copyright (c) 2008-2010, University of Manchester, The European Bioinformatics
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

ActionController::Routing::Routes.draw do |map|
  
  map.resource :curation
  
  map.api '/api.:format', :controller => 'api', :action => 'show' 
  
  map.lookup '/lookup.:format', :controller => 'lookup', :action => 'show'
  map.lookup '/lookup', :controller => 'lookup', :action => 'show'
  
  map.resources :announcements

  map.resources :service_tests,
                :member => { :results => :get,
                              :enable => :put,
                              :disable => :put}
  
  map.resources :test_results
  
  map.resources :test_scripts, 
                :member => { :download => :get }
  
  # To test error messages
  map.fail_page '/fail/:http_code', :controller => 'fail', :action => 'index'
  
  # Stats
  map.stats_index '/stats', :controller => 'stats', :action => 'index'
  map.refresh_stats '/stats/refresh', :controller => 'stats', :action => 'refresh', :conditions => { :method => :post }
  
  map.resources :categories,
                :member => { :services => :get }
  
  map.resources :registries,
                :member => { :annotations_by => :get,
                             :services => :get }
  
  map.resources :agents,
                :member => { :annotations_by => :get }
  
  # Routes from the favourites plugin + extensions
  Favourites.map_routes(map)

  # Routes from the annotations plugin + extensions
  Annotations.map_routes(map,
                         { :new_popup => :post,
                           :create_inline => :post,
                           :filters => :get,
                           :bulk_create => :post },
                         { :edit_popup => :post,
                           :download => :get,
                           :change_attribute => :post })
  
  map.resources :annotation_attributes,
                :member => { :annotations => :get }
  
  # Tags (ordering is important!)
#  map.tags_index '/tags', :controller => 'tags', :action => 'index', :conditions => { :method => :get }
#  map.tags_auto_complete '/tags/auto_complete', :controller => 'tags', :action => 'auto_complete', :conditions => { :method => :get }
#  map.tag_show '/tags/:tag_keyword', :controller => 'tags', :action => 'show', :conditions => { :method => :get }
#  map.destroy_tag '/tags', :controller => 'tags', :action => 'destroy', :conditions => { :method => :delete }
  
  map.resources :tags,
                :only => [ :index, :show, :destroy ],
                :collection => { :auto_complete => :get }

  # Ratings
  map.create_rating '/ratings', :controller => 'ratings', :action => 'create', :conditions => { :method => :post }
  map.destroy_rating '/ratings', :controller => 'ratings', :action => 'destroy', :conditions => { :method => :delete }
  
  # Search (ordering is important!)
  map.search_auto_complete '/search/auto_complete', :controller => 'search', :action => 'auto_complete', :conditions => { :method => :get }
  map.ignore_last_search '/search/ignore_last', :controller => 'search', :action => 'ignore_last', :conditions => { :method => :post }
  #map.connect '/search/:q', :controller => 'search', :action => 'show', :conditions => { :method => :get }
  map.search '/search.:format', :controller => 'search', :action => 'show', :conditions => { :method => :get }
  map.search '/search', :controller => 'search', :action => 'show', :conditions => { :method => [ :get, :post ] }
  map.search_by_data '/search/by_data.:format', :controller => 'search', :action => 'by_data', :conditions => { :method => [ :get, :post ] }
  map.search_by_data '/search/by_data', :controller => 'search', :action => 'by_data', :conditions => { :method => [ :post, :get ] }

  map.resources :service_providers,
                :member => { :annotations => :get,
                             :annotations_by => :get,
                             :services => :get }

  map.resources :service_deployments,
                :member => { :annotations => :get }

  #map.resources :service_versions

  map.resources :users, 
                :collection => { :activate_account => :get,
                                 :rpx_merge_setup => :get,
                                 :rpx_merge => :post }, 
                :member => { :change_password => [ :get, :post ],
                             :rpx_update => [ :get, :post ],
                             :annotations_by => :get,
                             :services => :get }
                
  map.resource :session

  if ENABLE_RPX
    map.rpx_token_sessions '/sessions/rpx_token', :controller => 'sessions', :action => 'rpx_token'
  end
  
  map.register '/register', :controller => 'users', :action => 'new'
  map.signup '/signup', :controller => 'users', :action => 'new'
  map.login '/login', :controller => 'sessions', :action => 'new'
  map.signin '/signin', :controller => 'sessions', :action => 'new'
  map.logout '/logout', :controller => 'sessions', :action => 'destroy', :conditions => { :method => :delete }
  map.activate_account '/activate_account/:security_token', :controller => 'users', :action => 'activate_account', :security_token => nil
  map.forgot_password '/forgot_password', :controller => 'users', :action => 'forgot_password'
  map.request_reset_password '/request_reset_password', :controller => 'users', :action => 'request_reset_password'
  map.reset_password '/reset_password/:security_token', :controller => 'users', :action => 'reset_password', :security_token => nil
  map.submit_feedback '/contact', :controller => 'contact', :action => 'create', :conditions => { :method => :post }
  map.contact '/contact', :controller => 'contact', :action => 'index', :conditions => { :method => :get }
  map.home '/', :controller => 'home', :action => 'index'
  map.activity_feed '/index.:format', :controller => 'home', :action => 'index'
  map.status_changes_feed '/status_changes.:format', :controller => 'home', :action => 'status_changes' 
  map.latest '/latest', :controller => 'home', :action => 'latest'

  map.service_provider_auto_complete 'service_providers/auto_complete', :controller => 'service_providers', :action => 'auto_complete', :conditions => { :method => :get }

  map.resources :rest_services,
                :member => { :annotations => :get,
                             :deployments => :get,
                             :update_base_endpoint => :post }

  map.resources :rest_resources, 
                :member => { :add_new_resources => :post }

  map.resources :rest_methods,
                :member => { :inline_add_endpoint_name => :post }

  map.resources :rest_parameters,
                :member => { :add_new_parameters => :post }

  map.resources :rest_method_parameters

  map.resources :rest_representations,
                :member => { :add_new_representations => :post }

  map.resources :rest_method_representations

  map.resources :soap_services,
                :collection => { :load_wsdl => :post,
                                 :bulk_new => :get,
                                 :wsdl_locations => :get },
                :member => { :annotations => :get,
                             :operations => :get,
                             :deployments => :get,
                             :latest_wsdl => :get }

  map.resources :soap_operations,
                :collection => { :filters => :get },
                :member => { :annotations => :get }
                
  map.resources :soap_inputs,
                :member => { :annotations => :get }
                
  map.resources :soap_outputs,
                :member => { :annotations => :get }

  map.resources :soaplab_servers,
                :collection => { :load_wsdl => :post}

  map.resources :services,
                :collection => { :filters => :get },
                :member => { :categorise => :post,
                             :summary => :get,
                             :annotations => :get,
                             :deployments => :get,
                             :variants => :get,
                             :monitoring => :get,
                             :check_updates => :post,
                             :archive => :post,
                             :unarchive => :post,
                             :activity => [ :get, :post ] }
                             
  map.resources :responsibility_requests,
                  :member => { :approve => :put,
                               :deny    => :put,
                               :turn_down => :get,
                               :cancel => :put}
  
  # Root of website
  map.root :controller => 'home', :action => 'index'

  # The priority is based upon order of creation: first created -> highest priority.

  # Sample of regular route:
  #   map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   map.resources :products

  # Sample resource route with options:
  #   map.resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }

  # Sample resource route with sub-resources:
  #   map.resources :products, :has_many => [ :comments, :sales ], :has_one => :seller

  # Sample resource route with more complex sub-resources
  #   map.resources :products do |products|
  #     products.resources :comments
  #     products.resources :sales, :collection => { :recent => :get }
  #   end

  # Sample resource route within a namespace:
  #   map.namespace :admin do |admin|
  #     # Directs /admin/products/* to Admin::ProductsController (app/controllers/admin/products_controller.rb)
  #     admin.resources :products
  #   end

  # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
  # map.root :controller => "welcome"

  # See how all your routes lay out with "rake routes"

  # Install the default routes as the lowest priority.
  map.connect ':controller/:action/:id'
  #map.connect ':controller/:action/:id.:format'
  
end
