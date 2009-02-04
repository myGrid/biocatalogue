# BioCatalogue: app/controllers/sessions_controller.rb
#
# Copyright (c) 2008, University of Manchester, The European Bioinformatics
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

class SessionsController < ApplicationController

  def new
    if not logged_in?
      session[:original_uri] = request.env['HTTP_REFERER'] unless session[:original_uri] != nil
    end
  end

  def create
    user = User.authenticate(params[:login], params[:password])
    if user
      session[:user_id] = user.id
      flash[:notice] = "Welcome #{user.display_name} !"

      session[:original_uri].blank? ? redirect_to(home_url) : redirect_to(session[:original_uri])
      session[:original_uri] = nil
    else
      flash[:error] = "Invalid email/password combination !"
      params[:password] = nil
      render :action => :new
    end
  end

  def destroy
    reset_session
    flash[:notice] = "You've been logged out."
    redirect_to home_url
  end

end
