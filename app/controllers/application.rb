# BioCatalogue: app/controllers/application.rb
#
# Copyright (c) 2008, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery :secret => 'bc5fa0462513829e6a733e8947c24994'
  
  # See ActionController::Base for details 
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password"). 
  # filter_parameter_logging :password

  layout "application_wide"
  
  def login_required
    respond_to do |format|
      format.html do
        if session[:user_id]
          @current_user = User.find(session[:user_id])
        else
          session[:original_uri] = request.request_uri
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
  # in the datatbase: assign 'role_id' to 1
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
      session[:original_uri] = request.request_uri
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
    else
      return false
    end
  end
  helper_method :mine?
  
  def set_sidebar_layout
    self.class.layout "application_sidebar"
  end
  
  def disable_action
    respond_to do |format|
      flash[:error] = 'The page requested is unavailable.'
      format.html { redirect_to(root_url) }
    end
    return false
  end
end
