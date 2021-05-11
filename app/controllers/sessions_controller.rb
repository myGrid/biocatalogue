# BioCatalogue: app/controllers/sessions_controller.rb
#
# Copyright (c) 2008-2010, University of Manchester, The European Bioinformatics
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

class SessionsController < ApplicationController

  before_filter :disable_login_and_registration, :only => [ :new, :create ]
  before_filter :disable_action_for_api
  
  skip_before_filter :verify_authenticity_token, :only => [ :rpx_token ]
  
  def new
  end
  
  def create
    user = User.authenticate(params[:login], params[:password])
    if user
      finish_login(user)
    else
			flash[:error] = "Unable to sign you in. The email or password you used may be incorrect, or your account might not be activated yet.".html_safe
      params[:password] = nil
      render :action => :new, :status => :unauthorized
    end
  end

  def destroy
    reset_session
    flash[:notice] = "You have been signed out.".html_safe
    redirect_to_back_or_home
  end
  
  def rpx_token
    if ENABLE_RPX
      begin
        if !params[:token].blank? && (data = RPXNow.user_data(params[:token]))
          user = User.find_by_identifier(data[:identifier])
          if user
            # Log user in
            session[:user_id] = user.id
            finish_login(user)
          else
            # Create a new user profile for this user.
            # Try and get as much info from their existing profile elsewhere.
            u = User.new
            u.identifier = data[:identifier]
            u.email = data[:email]
            u.email_confirmation = data[:email]
            u.display_name = data[:name]
            u.receive_notifications = true
            if u.save
              u.activate!
              finish_login(u, "<br/><br/><b>We have created a new account for you in #{SITE_NAME}. If you already had an account and would like to merge this new one with the existing one then <a href='#{rpx_merge_setup_users_url(:token => params[:token])}'>click here</a>.</b>".html_safe)
            else
              error_to_back_or_home("Sorry, we were unable to sign you in using your external account. This could be because we needed some information from you which was not supplied by your external account provider. Please try again. If this problem persists we would appreciate it if you contacted us.".html_safe)
            end
          end
        else
          error_to_back_or_home("Unable to sign you in. Please try again. If this problem persists we would appreciate it if you contacted us.".html_safe)
        end
      rescue Exception => ex
        logger.error "Failed to process RPX token. Exception: #{ex.class.name} - #{ex.message}"
        logger.error ex.backtrace.join("\n")
        error_to_back_or_home("Sorry, something went wrong. Please try again. If this problem persists we would appreciate it if you contacted us.")
      end
    else
      disable_action
    end
  end
  
  protected

  def disable_login_and_registration
    if defined? DISABLE_LOGIN && DISABLE_LOGIN
      flash[:error] = "Login/registration is disabled.".html_safe
      redirect_to_back_or_home
    end
  end
  
  def finish_login(user, additional_message ='')
    session[:user_id] = user.id
    
    flash[:notice] = "Welcome #{user.display_name}! #{additional_message}".html_safe

    if !params[:redirect_to].blank?
      redirect_to(params[:redirect_to])
    elsif !session[:previous_url].blank?
      redirect_to(session[:previous_url])
    else
      redirect_to(home_url)
    end
  end

end
