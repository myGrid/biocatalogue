# BioCatalogue: app/controllers/sessions_controller.rb
#
# Copyright (c) 2008, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

class SessionsController < ApplicationController

  def new
  end
  
  def create
    user = User.authenticate(params[:login], params[:password])
    if user
      session[:user_id] = user.id
      flash[:notice] = "Welcome #{user.display_name} !"
      #redirect_to session[:original_uri]
      # Redirect user to the URI of origin, or to homepage if no URI
      session[:original_uri] ? (redirect_to session[:original_uri]) : (redirect_to :users)

    else
      flash[:error] = "Invalid email/password combination !"
      params[:password] = nil
      render :action => :new
    end
  end
  
  def destroy
    reset_session
    flash[:notice] = "You've been logged out."
    redirect_to new_session_url
  end

end