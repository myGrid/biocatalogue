# BioCatalogue: app/config/routes.rb
#
# Copyright (c) 2008, University of Manchester, The European Bioinformatics
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

ActionController::Routing::Routes.draw do |map|
  
  # To test error messages
  map.fail_page '/fail/:http_code', :controller => 'fail', :action => 'index'
  
  # Stats
  map.stats_index '/stats', :controller => 'stats', :action => 'index'
  map.refresh_stats '/stats/refresh', :controller => 'stats', :action => 'refresh', :conditions => { :method => :post }
  
  map.resources :registries

  map.resources :agents
  
  # Routes from the favourites plugin + extensions
  Favourites.map_routes(map)

  # Routes from the annotations plugin + extensions
  Annotations.map_routes(map,
                         { :new_popup => :post },
                         { :edit_popup => :post })

  # Tags (ordering is important!)
  map.tags_index '/tags', :controller => 'tags', :action => 'index', :conditions => { :method => :get }
  map.tags_auto_complete '/tags/auto_complete', :controller => 'tags', :action => 'auto_complete', :conditions => { :method => :get }
  map.tag_show '/tags/:tag_keyword', :controller => 'tags', :action => 'show', :conditions => { :method => :get }
  map.destroy_tag '/tags', :controller => 'tags', :action => 'destroy', :conditions => { :method => :delete }

  # Ratings
  map.create_rating '/ratings', :controller => 'ratings', :action => 'create', :conditions => { :method => :post }
  map.destroy_rating '/ratings', :controller => 'ratings', :action => 'destroy', :conditions => { :method => :delete }
  
  # Search (ordering is important!)
  map.search '/search', :controller => 'search', :action => 'show', :conditions => { :method => [ :get, :post ] }
  map.search_auto_complete '/search/auto_complete', :controller => 'search', :action => 'auto_complete', :conditions => { :method => :get }
  map.ignore_last_search '/search/ignore_last', :controller => 'search', :action => 'ignore_last', :conditions => { :method => :post }
  map.connect '/search/:q', :controller => 'search', :action => 'show', :conditions => { :method => :get }
#  map.connect '/search.:format', :controller => 'search', :action => 'show'      # doesnt work in rails 2.3 for some reason
#  map.connect '/search.:format/:q', :controller => 'search', :action => 'show'     # doesnt work in rails 2.3 for some reason

  map.resources :service_providers

  #map.resources :service_deployments

  #map.resources :service_versions

  map.resources :users, :collection => { :activate_account => :get }, :member => { :change_password => [:get, :post] }
  map.resource :session

  map.register '/register', :controller => 'users', :action => 'new'
  map.signup '/signup', :controller => 'users', :action => 'new'
  map.login '/login', :controller => 'sessions', :action => 'new'
  map.logout '/logout', :controller => 'sessions', :action => 'destroy', :conditions => { :method => :delete }
  map.activate_account '/activate_account/:security_token', :controller => 'users', :action => 'activate_account', :security_token => nil
  map.forgot_password '/forgot_password', :controller => 'users', :action => 'forgot_password'
  map.reset_password '/reset_password/:security_token', :controller => 'users', :action => 'reset_password', :security_token => nil
  map.submit_feedback '/contact', :controller => 'contact', :action => 'create', :conditions => { :method => :post }
  map.contact '/contact', :controller => 'contact', :action => 'index', :conditions => { :method => :get }
  map.home '/', :controller => 'home', :action => 'index'

  map.resources :rest_services

  map.resources :soap_services,
                :collection => { :load_wsdl => :post,
                                 :bulk_new => :get }

  #map.resources :soap_operations
  #map.resources :soap_inputs
  #map.resources :soap_outputs

  map.resources :soaplab_servers,
                 :collection => { :load_wsdl => :post}

  map.resources :services,
                :member => { :categorise => :post }
  
  map.resources :service_tests, :collection => {:add_test => :post }

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
