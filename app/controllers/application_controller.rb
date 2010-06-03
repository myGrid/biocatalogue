# BioCatalogue: app/controllers/application_controller.rb
#
# Copyright (c) 2009-2010, University of Manchester, The European Bioinformatics
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

# ---
# Need to do this so that we play nice with the annotations and favourites plugin.
# THIS DOES UNFORTUNATELY MEAN THAT A SERVER RESTART IS REQUIRED WHENEVER CHANGES ARE MADE
# TO THIS FILE, EVEN IN DEVELOPMENT MODE.
require_dependency RAILS_ROOT + '/vendor/plugins/annotations/lib/app/controllers/application_controller'
require_dependency RAILS_ROOT + '/vendor/plugins/favourites/lib/app/controllers/application_controller'
#---

class ApplicationController < ActionController::Base
  
  before_filter { |controller|
    BioCatalogue::CacheHelper.set_base_host(controller.base_host)
  }

  
  # ============================================
  # Configure the Exception Notification plugin:
  # --------------------------------------------
  
  include ExceptionNotifiable

  # This line ensures that templates and mailing is enabled for the Exception Notification plugin
  # on your local development set up (so as to test the templates etc).
  # Note: error templates will only show in production mode.
  #
  # Be aware of this when configuring the email settings in biocat_local.rb -
  # in most cases you should disable email sending in your development setup 
  # (see config/initializers/mail.rb.pre for more info).
  local_addresses.clear
  
  self.rails_error_classes = { 
    ActiveRecord::RecordNotFound => "404",
    ::ActionController::UnknownController => "406",
    ::ActionController::UnknownAction => "406",
    ::ActionController::RoutingError => "406",
    ::ActionView::MissingTemplate => "406",
    ::ActionView::TemplateError => "500"
  }
  
  self.error_layout = "application_error"
  
  # ============================================
  
  
  helper :all # include all helpers, all the time
  
  helper_method :render_to_string

  # See ActionController::Base for details
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password").
  filter_parameter_logging :password

  protect_from_forgery

  layout "application_wide"
  
  before_filter :debug_messages
  
  before_filter :set_previous_url
  before_filter :set_page
  before_filter :set_per_page
  before_filter :set_limit
  before_filter :set_api_params
  before_filter :update_last_active
  prepend_before_filter :initialise_use_tab_cookie_in_session
  
  before_filter :set_up_log_event_core_data
  after_filter :log_event
  
  def login_required
    respond_to do |format|
      format.html do
        if session[:user_id]
          @current_user = User.find(session[:user_id])
        else
          flash[:notice] = "Please sign in to continue"
          redirect_to login_url
        end
      end
      format.xml  do
        user = authenticate_or_request_with_http_basic do |login, password|
          @current_user = User.authenticate(login, password)
        end
      end
      format.json  do
        user = authenticate_or_request_with_http_basic do |login, password|
          @current_user = User.authenticate(login, password)
        end
      end
    end
  end

  # Returns true or false if the user is logged in.
  def logged_in?
    return session[:user_id] ? true : false
  end
  helper_method :logged_in?

  # Check Administrator status for a user.
  # To make a user an Administrator, edit manually the user
  # in the database: assign 'role_id' to 1
  def is_admin?
    unless logged_in? && !current_user.nil? && current_user.role_id == 1
      return false
    else
      return true
    end
  end
  helper_method :is_admin?

  # Check that the user is an Administrator before allowing
  # the action to be performed and send it to the login page
  # if he isn't.
  # To make a user an Administrator, edit manually the user
  # in the datatbase: assign 'role_id' to 1
  def check_admin?
    unless logged_in? && !current_user.nil? && current_user.role_id == 1
      flash[:error] = "<b>Action denied.</b><p>This action is restricted to Administrators.</p>"
      redirect_to login_url
    end
  end
  helper_method :check_admin?

  # Accesses the current user from the session.
  def current_user
    @current_user ||= (session[:user_id] && User.find(session[:user_id])) || nil
  end
  helper_method :current_user

  # Check if an object belongs to the user logged in
  def mine?(thing)
    return false if thing.nil?
    return false unless logged_in?

    c_id = current_user.id.to_i

    case thing
    when User
      return c_id == thing.id
    when Annotation
      return thing.source == current_user
    when Service
      return c_id == thing.submitter_id.to_i
    when Favourite
      return c_id == thing.user_id
    else
      return false
    end
  end
  helper_method :mine?
  
  def display_name(item, escape_html=true)
    BioCatalogue::Util.display_name(item, escape_html)
  end
  helper_method :display_name
  
  # This takes into account the various idosyncracies and the data model 
  # to give you the best URL to something. 
  def url_for_web_interface(item)
    case item
      when Annotation, ServiceDeployment, ServiceVersion, SoapService, RestService
        service_id = BioCatalogue::Mapper.map_compound_id_to_associated_model_object_id(BioCatalogue::Mapper.compound_id_for(item.class.name, item.id), "Service")
        return service_url(service_id) unless service_id.nil?
      when SoapInput, SoapOutput
        return soap_operation_url(item.soap_operation_id, :anchor => "#{item.class.name.underscore}_#{item.id}") unless item.soap_operation_id.nil?
      when RestParameter, RestRepresentation
        service_id = BioCatalogue::Mapper.map_compound_id_to_associated_model_object_id(BioCatalogue::Mapper.compound_id_for(item.class.name, item.id), "Service")
        return service_url(service_id, :anchor => "endpoints") unless service_id.nil?
      else
        return url_for(item)  
    end
  end
  helper_method :url_for_web_interface
  
  # Returns the host url and its port
  def base_host
    request.host_with_port
  end

  protected
  
  def debug_messages
    BioCatalogue::Util.say ""
    BioCatalogue::Util.say "*** DEBUG MESSAGES ***"
    BioCatalogue::Util.say "ActionController#request.format = #{self.request.format.inspect}"
    BioCatalogue::Util.say "ActionController#request.format.html? = #{self.request.format.html?}"
    BioCatalogue::Util.say ""
  end
  
  def disable_action
    raise ActionController::UnknownAction.new
  end
  
  def disable_action_for_api
    if is_api_request?
      raise ActionController::UnknownAction.new
    else
      return
    end
  end
  
  def set_previous_url
    unless controller_name.downcase == 'sessions' or 
           [ 'activate_account', 'rpx_merge', 'ignore_last' ].include?(action_name.downcase) or
           is_non_html_request?
      session[:previous_url] = request.request_uri
    end
  end

  def set_page
    if self.request.format == :atom
      @page = 1
    else
      page = (params[:page] || 1).to_i
      if page < 1
        error("A wrong page number has been specified in the URL")
        return false
      else
        @page = page
      end
    end
    
  end
  
  def set_per_page
    if self.request.format == :atom
      @per_page = 20
    else
      per_page = (params[:per_page] || PAGE_ITEMS_SIZE).try(:to_i)
      if per_page < 1
        error("An invalid 'per page' number has been specified in the URL")
        return false
      elsif per_page > MAX_PAGE_SIZE
        @per_page = MAX_PAGE_SIZE
      else
        @per_page = per_page
      end
    end
    
  end
  
  def set_limit
    limit = params[:limit].try(:to_i)
    if limit and limit < 1
      error("A wrong limit has been specified in the URL")
      return false
    else
      @limit = limit
    end
  end
  
  def set_api_params
    @api_params = { }
    
    # 'include'
    @api_params[:include] = [ ]
    unless params[:include].blank?
       @api_params[:include] = params[:include].split(',').map{|s| s.strip.downcase}.compact
   end
   
   # 'also'
    @api_params[:also] = [ ]
    unless params[:also].blank?
       @api_params[:also] = params[:also].split(',').map{|s| s.strip.downcase}.compact
    end
  end
  
  # Generic method to raise / proceed from errors. 
  #
  # For HTML format: renders homepage (or redirects to previous URL), with an error message and appropriate HTTP status code.
  # For API formats: renders an error collection and appropriate HTTP status code.
  #
  # Options:
  # - :back_first - specifies whether to try to redirect back first (default: false).
  # - :forbidden - specifies whether this was a forbidden request or not (default: false).
  # - :status - specifies which HTTP Status code to use (default 403 or 400, depending on whether :forbidden is true or not [respectively]).
  #
  # Note: you should return (and in some cases return false) after using this method so that no other respond_to clash.
  def error(messages, *args)
    options = args.extract_options!
    # defaults:
    options.reverse_merge!(:back_first => false,
                           :forbidden => false,
                           :status => (options[:forbidden] ? 403 : 400))
    
    messages = [ messages ].flatten
    
    flash[:error] = messages.to_sentence
    
    if is_api_request?
      messages << "See http://apidocs.biocatalogue.org/ for information about the BioCatalogue REST API"
    end
    
    respond_to do |format|
      
      if options[:back_first] && !session[:previous_url].blank?
        format.html { redirect_to(session[:previous_url]) }
      else
        format.html { render "home/index", :status => options[:status] }
      end
      
      if options[:forbidden]
        format.xml  { head :forbidden }
        format.json { head :forbidden }
        format.atom { head :forbidden }
      else
        @errors = messages
        
        format.xml  { render "api/errors", :status => options[:status] }
        format.json { render :json => { "errors" => messages }.to_json, :status => options[:status] }
        format.atom { render :atom => "", :status => options[:status] }
      end
    end
  end

  # LEGACY METHOD
  # Generic method to raise / proceed from errors.
  #
  # For HTML format: redirects back to the previous page, OR the homepage.
  # For API formats: renders an error collection and appropriate HTTP status code.
  #
  # Note: you should return (and in some cases return false) after using this method so that no other respond_to clash.
  def error_to_back_or_home(msg, forbidden=false, status_code=(forbidden ? 403 : 400))
    error([ msg ], :back_first => true, :forbidden => forbidden, :status => status_code)
  end

  def is_request_from_bot?
    BOT_IGNORE_LIST.each do |bot|
      bot = bot.downcase
      if request.env['HTTP_USER_AGENT'] and request.env['HTTP_USER_AGENT'].downcase.match(bot)
        return true
      end
    end

    return false
  end
  
  def is_api_request?
#    OLD: return is_non_html_request? && !self.request.format.browser_generated? && !([ :all, :js ].include?(self.request.format.to_sym))

    return [ :xml, :atom, :json ].include?(self.request.format.to_sym)
  end
  
  def is_non_html_request?
#    mime_type_priority_x = if ActionController::Base.use_accept_header
#      Array(Mime::Type.lookup_by_extension(self.request.parameters[:format]) || self.request.accepts)
#    else
#      [self.request.format]
#    end
#    
#    puts ""
#    puts "*****"
#    puts ""
#    puts "ApplicationController#request.parameters[:format] = #{self.request.parameters[:format]}"
#    puts "ApplicationController#request.accepts = #{self.request.accepts.inspect}"
#    puts "ApplicationController#request.format = #{self.request.format.inspect}"
#    puts "mime_type_priority_x = #{mime_type_priority_x.inspect}"
#    puts ""
#    puts "*****"
#    puts ""
    
    return !self.request.format.html?
  end
  
  # ========================================
  # Code to help with remembering which tab
  # the user was in after redirects etc.
  # ----------------------------------------

  def initialise_use_tab_cookie_in_session
    #logger.info ""
    #logger.info "initialise_use_tab_cookie_in_session called; before - session[:use_tab_cookie] = #{session[:use_tab_cookie]}"
    #logger.info ""

    session[:use_tab_cookie] = false if session[:use_tab_cookie] == nil

    #logger.info ""
    #logger.info "initialise_use_tab_cookie_in_session called; after - session[:use_tab_cookie] = #{session[:use_tab_cookie]}"
    #logger.info ""
  end

  def add_use_tab_cookie_to_session
    #logger.info ""
    #logger.info "add_use_tab_cookie_to_session called; before - session[:use_tab_cookie] = #{session[:use_tab_cookie]}"
    #logger.info ""

    session[:use_tab_cookie] = true

    #logger.info ""
    #logger.info "add_use_tab_cookie_to_session called; after - session[:use_tab_cookie] = #{session[:use_tab_cookie]}"
    #logger.info ""
  end

  # ========================================
  
  
  # ===============================
  # Helpers for Filtering / Sorting
  # -------------------------------
  
  def parse_current_filters
    @current_filters = BioCatalogue::Filtering.convert_params_to_filters(params, controller_name.downcase.to_sym)
    puts "*** @current_filters = #{@current_filters.inspect}"
  end
  
  def generate_include_filter_url(filter_type, filter_value, resource, format=nil)
    new_params = BioCatalogue::Filtering.add_filter_to_params(params, filter_type, filter_value)
    return generate_filter_url(new_params, resource, format)
  end
  helper_method :generate_include_filter_url

  def generate_exclude_filter_url(filter_type, filter_value, resource, format=nil)
    new_params = BioCatalogue::Filtering.remove_filter_from_params(params, filter_type, filter_value)
    return generate_filter_url(new_params, resource, format)
  end
  helper_method :generate_exclude_filter_url
  
  # Note: the 'new_params' here MUST
  # - be a mutable params hash (so don't use the global 'params', duplicate it first using BioCatalogue::Util.duplicate_params(..)).
  # - contain filter params in the required Filter params spec. See: generate_include_filter_url above for ref.
  def generate_filter_url(new_params, resource, format=nil)
    # Remove special params
    new_params_cleaned = BioCatalogue::Util.remove_rails_special_params_from(new_params).reject{|k,v| [ "limit", "page", "namespace", "include", "also" ].include?(k.to_s.downcase) }
    
    unless format.nil?
      if format == :html
        new_params_cleaned.delete(:format)
      else
        new_params_cleaned[:format] = format unless format.nil?
      end
    end
    
    url = eval("#{resource}_url(new_params_cleaned)")
    
    return url
  end
  helper_method :generate_filter_url
  
  def is_filter_selected(filter_type, filter_value)
    return BioCatalogue::Filtering.is_filter_selected(@current_filters, filter_type, filter_value)
  end
  helper_method :is_filter_selected
  
  def generate_sort_url(sort_by, sort_order)
    params_dup = BioCatalogue::Util.duplicate_params(params)
    params_dup[:sort_by] = sort_by.downcase
    params_dup[:sort_order] = sort_order.downcase
      
    # Reset page param
    params_dup.delete(:page)
    
    return services_url(params_dup)
  end
  helper_method :generate_sort_url
  
  def is_sort_selected(sort_by, sort_order)
    return params[:sort_by] == sort_by.downcase && params[:sort_order] == sort_order.downcase
  end
  helper_method :is_sort_selected
  
  def get_filter_groups
    @filter_groups = BioCatalogue::Filtering.get_all_filter_groups_for(self.controller_name.underscore.to_sym, @limit || 200)
  end
  
  # ===============================
 
  
  def set_up_log_event_core_data
    if USE_EVENT_LOG and !is_request_from_bot?
      format = self.request.format.to_sym.to_s
      @log_event_core_data = { :format => format, :user_agent => request.env['HTTP_USER_AGENT'], :http_referer =>  request.env['HTTP_REFERER'] }
    end
  end

  # Used to record certain events that are of importance...
  def log_event

    if USE_EVENT_LOG and !is_request_from_bot?
      
      c = self.controller_name.downcase
      a = self.action_name.downcase
      
      do_generic_log = false
      
      case c
        
        # Search
        when "search"
          
          case a
            # Standard keyword based search
            when "show"
              if !@query.blank? and !@scope.blank? and @page == 1
                ActivityLog.create(@log_event_core_data.merge(:action => "search", :culprit => current_user, :data => { :query => @query, :type =>  @scope, :per_page => @per_page }))
              end
            # Special "by data" search
            when "by_data"
              if !@query.blank?
                ActivityLog.create(@log_event_core_data.merge(:action => "search_by_data", :culprit => current_user, :data => { :query => @query, :search_type =>  @search_type, :limit => @limit }))
              end
            else
              do_generic_log = true
          end
      
        # Services    
        when "services"
        
          case a
            # View service
            when "show"
              ActivityLog.create(@log_event_core_data.merge(:action => "view",
                                 :culprit => current_user,
                                 :activity_loggable => @service))
            # View index of services
            when "index"
              ActivityLog.create(@log_event_core_data.merge(:action => "view_services_index",
                                 :culprit => current_user,
                                 :data => { :query => params[:q], :filters => @current_filters, :page => @page, :per_page => @per_page }))
            
              # Log a search as well, if a search query was specified. 
              unless params[:q].blank? and @page == 1
                ActivityLog.create(@log_event_core_data.merge(:action => "search", :culprit => current_user, :data => { :query => params[:q], :type =>  "services", :per_page => @per_page }))
              end
            else
              do_generic_log = true
          end
        
        # Users
        when "users"
        
          case a 
            # View user profile
            when "show"
              if current_user.try(:id) != @user.id
                ActivityLog.create(@log_event_core_data.merge(:action => "view",
                                   :culprit => current_user,
                                   :activity_loggable => @user))
              end
            else
              do_generic_log = true
          end
      
        # Registries
        when "registries"
          
          case a
            # View registry profile
            when "show"
              ActivityLog.create(@log_event_core_data.merge(:action => "view",
                                 :culprit => current_user,
                                 :activity_loggable => @registry))
            else
              do_generic_log = true
          end

        # Service Providers  
        when "service_providers"
          
          case a
            # View service provider profile
            when "show"
              ActivityLog.create(@log_event_core_data.merge(:action => "view",
                                 :culprit => current_user,
                                 :activity_loggable => @service_provider))
            else
              do_generic_log = true
          end
      
        # Annotations
        when "annotations"
        
          case a
            # Download annotation
            when "download"
              ActivityLog.create(@log_event_core_data.merge(:action => "download",
                                 :culprit => current_user,
                                 :activity_loggable => @annotation))
            else
              do_generic_log = true
          end
        
        else
          do_generic_log = true
      
      end
    
      if do_generic_log
        # Only log generically if it is an API request...
        if is_api_request?
          ActivityLog.create(@log_event_core_data.merge(:action => "#{c}_controller #{a}",
                             :culprit => current_user,
                             :data => { :params => params }))
        end
      end
      
    end

  end

  def update_last_active
    if logged_in?
      current_user.update_last_active(Time.now())
    end
  end
  
end
