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
end
