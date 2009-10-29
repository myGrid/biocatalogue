# BioCatalogue: app/controllers/application_controller.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics
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

  include ExceptionNotifiable

  # This line ensures that templates and mailing is enabled for the Exception Notification plugin
  # on your local development set up (so as to test the templates etc).
  # Note: error templates will only show in production mode.
  #
  # Be aware of this when configuring the email settings in biocat_local.rb -
  # in most cases you should disable email sending in your development setup (see biocat_local.rb.pre for more info).
  local_addresses.clear
  
  # Mainly for the Exception Notification plugin:
  self.rails_error_classes = { 
    ActiveRecord::RecordNotFound => "404",
    ::ActionController::UnknownController => "404",
    ::ActionController::UnknownAction => "404",
    ::ActionController::RoutingError => "404",
    ::ActionView::MissingTemplate => "500",
    ::ActionView::TemplateError => "500"
  }

  helper :all # include all helpers, all the time
  
  helper_method :render_to_string

  # See ActionController::Base for details
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password").
  filter_parameter_logging :password

  protect_from_forgery

  layout "application_wide"

  before_filter :set_previous_url
  before_filter :set_page
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
        user = authenticate_with_http_basic do |login, password|
          User.authenticate(login, password)
        end
        if user
          @current_user = user
        else
          request_http_basic_authentication
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

  # Returns the host url and its port
  def base_host
    request.host_with_port
  end

  protected

  def disable_action
    raise ActionController::UnknownAction.new
  end

  def set_previous_url
    unless (controller_name.downcase == 'sessions') or 
      ([ 'activate_account', 'rpx_merge', 'ignore_last' ].include?(action_name.downcase))
      session[:previous_url] = request.request_uri unless is_non_html_request?
    end
  end

  def set_page
    page = (params[:page] || 1).to_i
    if page < 1
      error_to_home("A wrong page number has been specified in the URL")
      return false
    else
      @page = page
    end
  end
  
  # Generic method to raise / proceed from errors. Redirects to home.
  # Note: you should return (and in some cases return false) after using this method so that no other respond_to clashes.
  def error_to_home(msg)
    flash[:error] = msg

    respond_to do |format|
      format.html { redirect_to home_url }
      format.xml { render :xml => "<errors><error>#{msg}</error></errors>" }
    end
  end

  # Generic method to raise / proceed from errors. Redirects to the previous page or if not available, to home.
  # Note: you should return (and in some cases return false) after using this method so that no other respond_to clashes.
  def error_to_back_or_home(msg)
    flash[:error] = msg

    respond_to do |format|
      format.html { redirect_to(session[:previous_url].blank? ? home_url : session[:previous_url]) }
      format.xml { render :xml => "<errors><error>#{msg}</error></errors>" }
    end
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
  
  def is_non_html_request?
    return (!params[:format].nil? and params[:format] != "html" and params[:format] != "htm")
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
  
  def set_up_log_event_core_data
    if USE_EVENT_LOG and !is_request_from_bot?
      format = ((params[:format].blank? or params[:format].downcase == "htm") ? "html" : params[:format].to_s.downcase)
      @log_event_core_data = { :format => format, :user_agent => request.env['HTTP_USER_AGENT'], :http_referer =>  request.env['HTTP_REFERER'] }
    end
  end

  # Used to record certain events that are of importance...
  def log_event

    if USE_EVENT_LOG and !is_request_from_bot?

      c = controller_name.downcase
      a = action_name.downcase
        
      # Search
      if c == "search"
        if a == "show"
          if !@query.blank? and !@scope.blank? and @page == 1
            ActivityLog.create(@log_event_core_data.merge(:action => "search", :culprit => current_user, :data => { :query => @query, :type =>  @scope }))
          end
        end
      end
      
      if c == "services"
        # View service
        if a == "show"
          ActivityLog.create(@log_event_core_data.merge(:action => "view",
                             :culprit => current_user,
                             :activity_loggable => @service))
        end
        
        # View index of services
        if a == "index"
          ActivityLog.create(@log_event_core_data.merge(:action => "view_services_index",
                             :culprit => current_user,
                             :data => { :query => params[:q], :filters => @current_filters }))
        
          # Log a search as well, if a search query was specified. 
          unless params[:q].blank?
            ActivityLog.create(@log_event_core_data.merge(:action => "search", :culprit => current_user, :data => { :query => params[:q], :type =>  "services", :filters => @current_filters }))
          end
        end
      end
      
      if c == "users"
        # View user profile
        if a == "show"
          if current_user.try(:id) != @user.id
            ActivityLog.create(@log_event_core_data.merge(:action => "view",
                               :culprit => current_user,
                               :activity_loggable => @user))
          end
        end
      end
      
      if c == "registries"
        # View registry profile
        if a == "show"
          ActivityLog.create(@log_event_core_data.merge(:action => "view",
                             :culprit => current_user,
                             :activity_loggable => @registry))
        end
      end
      
      if c == "service_providers"
        # View service provider profile
        if a == "show"
          ActivityLog.create(@log_event_core_data.merge(:action => "view",
                             :culprit => current_user,
                             :activity_loggable => @service_provider))
        end
      end
      
      if c == "annotations"
        # Download annotation
        if a == "download"
          ActivityLog.create(@log_event_core_data.merge(:action => "download",
                             :culprit => current_user,
                             :activity_loggable => @annotation))
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
