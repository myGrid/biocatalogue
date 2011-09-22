# BioCatalogue: app/config/routes.rb
#
# Copyright (c) 2008-2010, University of Manchester, The European Bioinformatics
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

ActionController::Routing::Routes.draw do |map|

  ROUTES_PROTOCOL = (ENABLE_SSL && Rails.env.production? ? 'https' : 'http')
  
  #

  map.resources :oauth_clients, :requirements => { :protocol => ROUTES_PROTOCOL }

  map.test_request '/oauth/test_request', :controller => 'oauth', :action => 'test_request', :requirements => { :protocol => ROUTES_PROTOCOL }
  map.access_token '/oauth/access_token', :controller => 'oauth', :action => 'access_token', :requirements => { :protocol => ROUTES_PROTOCOL }
  map.request_token '/oauth/request_token', :controller => 'oauth', :action => 'request_token', :requirements => { :protocol => ROUTES_PROTOCOL }
  map.authorize '/oauth/authorize', :controller => 'oauth', :action => 'authorize', :requirements => { :protocol => ROUTES_PROTOCOL }
  map.oauth '/oauth', :controller => 'oauth', :action => 'index', :requirements => { :protocol => ROUTES_PROTOCOL }
  
  # =========================
  # Curation Dashboard routes
  # -------------------------
  
  # Main
  
   map.curation '/curation',
    :controller => 'curation',
    :action => 'show',
    :conditions => { :method => :get },
    :requirements => { :protocol => ROUTES_PROTOCOL }

  # Reports
  
  map.curation_reports_potential_duplicate_operations_within_service '/curation/reports/potential_duplicate_operations_within_service', 
    :controller => 'curation', 
    :action => 'potential_duplicate_operations_within_service', 
    :conditions => { :method => :get },
    :requirements => { :protocol => ROUTES_PROTOCOL }
    
  map.curation_reports_providers_without_services '/curation/reports/providers_without_services', 
    :controller => 'curation', 
    :action => 'providers_without_services', 
    :conditions => { :method => :get },
    :requirements => { :protocol => ROUTES_PROTOCOL }

  map.curation_reports_services_missing_annotations '/curation/reports/services_missing_annotations',
    :controller => 'curation',
    :action => 'services_missing_annotations',
    :conditions => { :method => [ :get, :post ] },
    :requirements => { :protocol => ROUTES_PROTOCOL }
  
  # Tools
  
  map.curation_tools_copy_annotations '/curation/tools/copy_annotations',
    :controller => 'curation', 
    :action => 'copy_annotations', 
    :conditions => { :method => [ :get, :post ] },
    :requirements => { :protocol => ROUTES_PROTOCOL }
  
  map.curation_tools_copy_annotations_preview '/curation/tools/copy_annotations_preview',
    :controller => 'curation', 
    :action => 'copy_annotations_preview', 
    :conditions => { :method => :post },
    :requirements => { :protocol => ROUTES_PROTOCOL }
       
  map.curation_annotation_level '/curation/reports/annotation_level', 
    :controller => 'curation', 
    :action => 'annotation_level', 
    :conditions => { :method => :get },
    :requirements => { :protocol => ROUTES_PROTOCOL }
     
  # =========================
  
  
  map.api '/api.:format', :controller => 'api', :action => 'show', :requirements => { :protocol => ROUTES_PROTOCOL } 
  
  map.lookup '/lookup.:format', :controller => 'lookup', :action => 'show', :requirements => { :protocol => ROUTES_PROTOCOL }
  map.lookup '/lookup', :controller => 'lookup', :action => 'show', :requirements => { :protocol => ROUTES_PROTOCOL }
  
  map.resources :announcements, :requirements => { :protocol => ROUTES_PROTOCOL }

  map.resources :service_tests,
                :member => { :results => :get,
                             :enable => :put,
                             :disable => :put },
                :requirements => { :protocol => ROUTES_PROTOCOL }
  
  map.resources :test_results, :requirements => { :protocol => ROUTES_PROTOCOL }
  
  map.resources :test_scripts, 
                :member => { :download => :get },
                :requirements => { :protocol => ROUTES_PROTOCOL }
  
  # To test error messages
  map.fail_page '/fail/:http_code', :controller => 'fail', :action => 'index', :requirements => { :protocol => ROUTES_PROTOCOL }
  
  # Stats
  map.stats_index '/stats', :controller => 'stats', :action => 'index', :requirements => { :protocol => ROUTES_PROTOCOL }
  map.refresh_stats '/stats/refresh', :controller => 'stats', :action => 'refresh', :conditions => { :method => :post }, :requirements => { :protocol => ROUTES_PROTOCOL }
  map.resources :stats, :requirements => { :protocol => ROUTES_PROTOCOL }
  
  map.resources :categories,
                :member => { :services => :get },
                :requirements => { :protocol => ROUTES_PROTOCOL }
  
  map.resources :registries,
                :member => { :annotations_by => :get,
                             :services => :get },
                :requirements => { :protocol => ROUTES_PROTOCOL }
  
  map.resources :agents,
                :member => { :annotations_by => :get },
                :requirements => { :protocol => ROUTES_PROTOCOL }
  
  # Routes from the favourites plugin + extensions
  Favourites.map_routes(map, {}, {}, { :protocol => ROUTES_PROTOCOL })

  # Routes from the annotations plugin + extensions
  Annotations.map_routes(map,
                         { :new_popup => :post,
                           :create_inline => :post,
                           :filters => :get,
                           :filtered_index => :post,
                           :bulk_create => :post },
                         { :edit_popup => :post,
                           :download => :get,
                           :promote_alternative_name => :post },
                         { :protocol => ROUTES_PROTOCOL })
  
  map.resources :annotation_attributes,
                :member => { :annotations => :get },
                :requirements => { :protocol => ROUTES_PROTOCOL }
  
  # Tags (ordering is important!)
#  map.tags_index '/tags', :controller => 'tags', :action => 'index', :conditions => { :method => :get }
#  map.tags_auto_complete '/tags/auto_complete', :controller => 'tags', :action => 'auto_complete', :conditions => { :method => :get }
#  map.tag_show '/tags/:tag_keyword', :controller => 'tags', :action => 'show', :conditions => { :method => :get }
#  map.destroy_tag '/tags', :controller => 'tags', :action => 'destroy', :conditions => { :method => :delete }
  
  map.resources :tags,
                :only => [ :index, :show, :destroy ],
                :collection => { :auto_complete => :get,
                                 :destroy_taggings => :delete },
                :requirements => { :protocol => ROUTES_PROTOCOL }

  # Search (ordering is important!)
  map.search_auto_complete '/search/auto_complete', :controller => 'search', :action => 'auto_complete', :conditions => { :method => :get }, :requirements => { :protocol => ROUTES_PROTOCOL }
  map.ignore_last_search '/search/ignore_last', :controller => 'search', :action => 'ignore_last', :conditions => { :method => :post }, :requirements => { :protocol => ROUTES_PROTOCOL }
  #map.connect '/search/:q', :controller => 'search', :action => 'show', :conditions => { :method => :get }
  map.search '/search.:format', :controller => 'search', :action => 'show', :conditions => { :method => [ :get, :post ] }, :requirements => { :protocol => ROUTES_PROTOCOL }
  map.search '/search', :controller => 'search', :action => 'show', :conditions => { :method => [ :get, :post ] }, :requirements => { :protocol => ROUTES_PROTOCOL }
  map.search_by_data '/search/by_data.:format', :controller => 'search', :action => 'by_data', :conditions => { :method => [ :get, :post ] }, :requirements => { :protocol => ROUTES_PROTOCOL }
  map.search_by_data '/search/by_data', :controller => 'search', :action => 'by_data', :conditions => { :method => [ :post, :get ] }, :requirements => { :protocol => ROUTES_PROTOCOL }

  map.resources :service_providers,
                :collection => { :filters => :get,
                                 :filtered_index => :post },
                :member => { :annotations => :get,
                             :annotations_by => :get,
                             :services => :get },
                :requirements => { :protocol => ROUTES_PROTOCOL }
  
  map.resources :service_provider_hostnames, :requirements => { :protocol => ROUTES_PROTOCOL }
  
  map.resources :service_deployments,
                :member => { :annotations => :get },
                :requirements => { :protocol => ROUTES_PROTOCOL }

  #map.resources :service_versions

  map.resources :users, 
                :collection => { :activate_account => :get,
                                 :rpx_merge_setup => :get,
                                 :rpx_merge => :post,
                                 :filters => :get,
                                 :filtered_index => :post,
                                 :whoami => :get }, 
                :member => { :change_password => [ :get, :post ],
                             :rpx_update => [ :get, :post ],
                             :annotations_by => :get,
                             :services => :get,
                             :saved_searches => :get,
                             :favourites => :get,
                             :services_responsible => :get,
                             :make_curator => :put,
                             :remove_curator => :put,
                             :deactivate => :put },
                :requirements => { :protocol => ROUTES_PROTOCOL }
                
  map.resource :session, :requirements => { :protocol => ROUTES_PROTOCOL }

  if ENABLE_RPX
    map.rpx_token_sessions '/sessions/rpx_token', :controller => 'sessions', :action => 'rpx_token', :requirements => { :protocol => ROUTES_PROTOCOL }
  end
  
  map.register '/register', :controller => 'users', :action => 'new', :requirements => { :protocol => ROUTES_PROTOCOL }
  map.signup '/signup', :controller => 'users', :action => 'new', :requirements => { :protocol => ROUTES_PROTOCOL }
  map.login '/login', :controller => 'sessions', :action => 'new', :requirements => { :protocol => ROUTES_PROTOCOL }
  map.signin '/signin', :controller => 'sessions', :action => 'new', :requirements => { :protocol => ROUTES_PROTOCOL }
  map.logout '/logout', :controller => 'sessions', :action => 'destroy', :conditions => { :method => :delete }, :requirements => { :protocol => ROUTES_PROTOCOL }
  map.activate_account '/activate_account/:security_token', :controller => 'users', :action => 'activate_account', :security_token => nil, :requirements => { :protocol => ROUTES_PROTOCOL }
  map.forgot_password '/forgot_password', :controller => 'users', :action => 'forgot_password', :requirements => { :protocol => ROUTES_PROTOCOL }
  map.request_reset_password '/request_reset_password', :controller => 'users', :action => 'request_reset_password', :requirements => { :protocol => ROUTES_PROTOCOL }
  map.reset_password '/reset_password/:security_token', :controller => 'users', :action => 'reset_password', :security_token => nil, :requirements => { :protocol => ROUTES_PROTOCOL }
  map.submit_feedback '/contact', :controller => 'contact', :action => 'create', :conditions => { :method => :post }, :requirements => { :protocol => ROUTES_PROTOCOL }
  map.contact '/contact', :controller => 'contact', :action => 'index', :conditions => { :method => :get }, :requirements => { :protocol => ROUTES_PROTOCOL }
  map.home '/', :controller => 'home', :action => 'index', :requirements => { :protocol => ROUTES_PROTOCOL }
  map.activity_feed '/index.:format', :controller => 'home', :action => 'index', :requirements => { :protocol => ROUTES_PROTOCOL }
  map.status_changes_feed '/status_changes.:format', :controller => 'home', :action => 'status_changes', :requirements => { :protocol => ROUTES_PROTOCOL }
  map.latest '/latest', :controller => 'home', :action => 'latest', :requirements => { :protocol => ROUTES_PROTOCOL }

  map.service_provider_auto_complete 'service_providers/auto_complete', :controller => 'service_providers', :action => 'auto_complete', :conditions => { :method => :get }, :requirements => { :protocol => ROUTES_PROTOCOL }

  map.resources :rest_services,
                :member => { :annotations => :get,
                             :deployments => :get,
                             :update_base_endpoint => :post,
                             :resources => :get,
                             :methods => :get },
                :requirements => { :protocol => ROUTES_PROTOCOL }
                
  map.resources :rest_resources, 
                :member => { :add_new_resources => :post,
                             :annotations => :get,
                             :methods => :get },
                :requirements => { :protocol => ROUTES_PROTOCOL }

  map.resources :rest_methods,
                :collection => { :filters => :get,
                                 :filtered_index => :post },
                :member => { :inline_add_endpoint_name => :post,
                             :edit_group_name_popup => :post,
                             :update_group_name => :post,
                             :group_name_auto_complete => :post,
                             :inputs => :get,
                             :outputs => :get,
                             :annotations => :get },
                :requirements => { :protocol => ROUTES_PROTOCOL }
                
  map.resources :rest_parameters,
                :member => { :add_new_parameters => :post,
                             :annotations => :get },
                :requirements => { :protocol => ROUTES_PROTOCOL }
                
  map.resources :rest_method_parameters, :requirements => { :protocol => ROUTES_PROTOCOL }

  map.resources :rest_representations,
                :member => { :add_new_representations => :post,
                             :annotations => :get },
                :requirements => { :protocol => ROUTES_PROTOCOL }

  map.resources :rest_method_representations, :requirements => { :protocol => ROUTES_PROTOCOL }

  map.resources :soap_services,
                :collection => { :load_wsdl => :post,
                                 :bulk_new => :get,
                                 :wsdl_locations => :get },
                :member => { :annotations => :get,
                             :operations => :get,
                             :deployments => :get,
                             :latest_wsdl => :get },
                :requirements => { :protocol => ROUTES_PROTOCOL }

  map.resources :soap_operations,
                :collection => { :filters => :get,
                                 :filtered_index => :post },
                :member => { :annotations => :get,
                             :inputs => :get,
                             :outputs => :get },
                :requirements => { :protocol => ROUTES_PROTOCOL }
                
  map.resources :soap_inputs,
                :member => { :annotations => :get },
                :requirements => { :protocol => ROUTES_PROTOCOL }
                
  map.resources :soap_outputs,
                :member => { :annotations => :get },
                :requirements => { :protocol => ROUTES_PROTOCOL }

  map.resources :soaplab_servers,
                :collection => { :load_wsdl => :post},
                :requirements => { :protocol => ROUTES_PROTOCOL }

  map.resources :services,
                :collection => { :filters => :get,
                                 :filtered_index => :post },
                :member => { :categorise => :post,
                             :summary => :get,
                             :annotations => :get,
                             :deployments => :get,
                             :variants => :get,
                             :monitoring => :get,
                             :check_updates => :post,
                             :archive => :post,
                             :unarchive => :post,
                             :favourite => :post,
                             :unfavourite => :post,
                             :activity => :get,
                             :examples => :get },
                :requirements => { :protocol => ROUTES_PROTOCOL }
                             
  map.resources :responsibility_requests,
                :member => { :approve => :put,
                             :deny    => :put,
                             :turn_down => :get,
                             :cancel => :put},
                :requirements => { :protocol => ROUTES_PROTOCOL }
  
  map.resources :service_responsibles,
                :member => {:activate => :put,
                            :deactivate => :put },
                :requirements => { :protocol => ROUTES_PROTOCOL }
  
  map.resources :saved_searches, :requirements => { :protocol => ROUTES_PROTOCOL }

  # Root of website
  map.root :controller => 'home', :action => 'index', :requirements => { :protocol => ROUTES_PROTOCOL }

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
