# BioCatalogue: app/controllers/application.rb
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
require_dependency RAILS_ROOT + '/vendor/plugins/annotations/lib/app/controllers/application'
require_dependency RAILS_ROOT + '/vendor/plugins/favourites/lib/app/controllers/application'
#---

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery :secret => 'bc5fa0462513829e6a733e8947c24994'

  # See ActionController::Base for details
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password").
  filter_parameter_logging :password

  layout "application_wide"

  before_filter :set_original_uri
  
  prepend_before_filter :initialise_use_tab_cookie_in_session
  
  after_filter :log_event
  
  def login_required
    respond_to do |format|
      format.html do
        if session[:user_id]
          @current_user = User.find(session[:user_id])
        else
          #session[:original_uri] = request.request_uri
          flash[:notice] = "Please log in"
          redirect_to new_session_url
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
      #session[:original_uri] = request.request_uri
      flash[:error] = "<b>Action denied.</b><p>This action is restricted to Administrators.</p>"
      redirect_to new_session_url
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

    case thing.class.to_s
    when "User"
      return c_id == thing.id
    when "Annotation"
      return thing.source == current_user
    when "Service"
      return c_id == thing.submitter_id.to_i
    when "Favourite"
      return c_id == thing.user_id
    else
      return false
    end
  end
  helper_method :mine?
  
  protected

  def set_sidebar_layout
    self.class.layout "application_sidebar"
  end

  def set_no_layout
    self.class.layout nil
  end

  def disable_action
    # This will cause a 404...
    raise ActionController::UnknownAction.new
  end

  def set_original_uri
    unless controller_name.downcase == 'sessions' || action_name.downcase == 'activate_account'
      session[:original_uri] = request.request_uri if not logged_in?
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
      format.html { redirect_to(session[:original_uri].blank? ? home_url : :back) }
      format.xml { render :xml => "<errors><error>#{msg}</error></errors>" }
    end
  end
  
  def is_request_from_bot?
    if @is_bot.nil?
      @is_bot = false
    
      BOT_IGNORE_LIST.each do |bot|
        if request.env['HTTP_USER_AGENT'] and request.env['HTTP_USER_AGENT'].match(bot)
          @is_bot = true
          break
        end 
      end
    end
    
    return @is_bot
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
  
  
  # =========================
  # Helper methods for Search
  # -------------------------
  
  def validate_and_setup_search
    
    # First check that search is available
    unless BioCatalogue::Search.available?
      error_to_home('Search is unavailable at this time')
      return false
    end
    
    query = (params[:q] || '').strip
    
    # Check query is present
    unless query.blank?
      
      # Check if the query is '*' in which case give the user an appropriate message.
      if query == '*'
        error_to_home("It looks like you were trying to search for everything in the BioCatalogue! If you would like to browse all services then <a href='#{services_path}'>click here</a>.")
        return false
      end
      
      # Query is fine...
      @query = query
      
      type = params[:t]
      
      if type.blank?
        if controller_name.downcase == "search"
          type = "all"
        else
          type = controller_name.downcase
        end
      else
        type = type.strip.downcase.pluralize
      end
      
      all_valid_types = BioCatalogue::Search::VALID_SEARCH_TYPES + BioCatalogue::Search::ALL_TYPES_SYNONYMS
      
      # Check that a valid type has been provided
      unless all_valid_types.include?(type)
        error_to_home("'#{type}' is an invalid search type")
        return false
      end
      
      # Type is fine...
      @type = type
      
      @results = nil
      
    end
    
  end
  
  def log_search
    if USE_EVENT_LOG
      if !@query.blank? and !@type.blank?
        ActivityLog.create(:action => "search", :culprit => current_user, :data => { :query => @query, :type =>  @type, :http_user_agent => request.env['HTTP_USER_AGENT'], :http_referer =>  request.env['HTTP_REFERER'] })
      end
    end
  end
  
  # =========================
  
  # Used to record certain events that are of importance...
  def log_event
    # Note: currently the following are logged seperately:
    # - searches
    
    if USE_EVENT_LOG and !is_request_from_bot?
      
      c = controller_name.downcase
      a = action_name.downcase
        
      core_data = { :http_user_agent => request.env['HTTP_USER_AGENT'], :http_referer =>  request.env['HTTP_REFERER'] }
      
      if c == "services"
        if a == "show"
          ActivityLog.create(:action => "view", 
                             :culprit => current_user, 
                             :activity_loggable => @service, 
                             :data => core_data)  
        end
      end
      
      if c == "users"
        if a == "show"
          ActivityLog.create(:action => "view", 
                             :culprit => current_user, 
                             :activity_loggable => @user, 
                             :data => core_data)
        end
      end
      
      if c == "registries"
        if a == "show"
          ActivityLog.create(:action => "view", 
                             :culprit => current_user, 
                             :activity_loggable => @registry, 
                             :data => core_data)
        end
      end
      
      if c == "service_providers"
        if a == "show"
          ActivityLog.create(:action => "view", 
                             :culprit => current_user, 
                             :activity_loggable => @service_provider, 
                             :data => core_data)
        end
      end
      
    end
  end
end
