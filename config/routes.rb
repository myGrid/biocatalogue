# BioCatalogue: app/config/routes.rb
#
# Copyright (c) 2008, University of Manchester, The European Bioinformatics
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

ActionController::Routing::Routes.draw do |map|

  # Routes from the annotations plugin + extensions
  Annotations.map_routes(map,
                         { :new_popup => :post },
                         { :edit_popup => :post })

  # Tags
  map.tags_index '/tags', :controller => 'tags', :action => 'index', :conditions => { :method => :get }
  map.tags_auto_complete '/tags/auto_complete', :controller => 'tags', :action => 'auto_complete', :conditions => { :method => :get }
  map.tag_show '/tags/:tag', :controller => 'tags', :action => 'show', :conditions => { :method => :get }

  # Search
  map.search '/search', :controller => 'search', :action => 'show'
  map.connect '/search.:format', :controller => 'search', :action => 'show'
  map.connect '/search/:query', :controller => 'search', :action => 'show'
  map.connect '/search.:format/:query', :controller => 'search', :action => 'show'

  map.resources :service_providers

  #map.resources :service_deployments

  #map.resources :service_versions

  map.resources :users, :collection => { :activate_account => :get }
  map.resource :session

  map.register '/register', :controller => 'users', :action => 'new'
  map.signup '/signup', :controller => 'users', :action => 'new'
  map.login '/login', :controller => 'sessions', :action => 'new'
  map.logout '/logout', :controller => 'sessions', :action => 'destroy', :conditions => { :method => :delete }
  map.activate_account '/activate_account/:security_token', :controller => 'users', :action => 'activate_account', :security_token => nil
  map.forgot_password '/forgot_password', :controller => 'users', :action => 'forgot_password'
  map.reset_password '/reset_password/:security_token', :controller => 'users', :action => 'reset_password', :security_token => nil
  map.contact '/contact', :controller => 'contact', :action => 'index'
  map.home '/', :controller => 'home', :action => 'index'

  map.resources :soap_services,
                :collection => { :load_wsdl => :post,
                                 :bulk_new => :get }

  #map.resources :soap_operations
  #map.resources :soap_inputs
  #map.resources :soap_outputs

  map.resources :soaplab_servers,
                 :collection => { :load_wsdl => :post}

  map.resources :services

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
