# BioCatalogue: app/controllers/oauth_clients_controller.rb
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

class OauthClientsController < ApplicationController
  
  before_filter :disable_action_for_api
  
  before_filter :login_required
  
  before_filter :get_client_application, :only => [ :show, :edit, :update, :destroy ]
  
  before_filter :authorise, :only => [ :show, :edit, :update, :destroy ]
   
  def index
    @client_applications = current_user.client_applications
    @tokens = current_user.tokens.find :all, :conditions => 'oauth_tokens.invalidated_at is null and oauth_tokens.authorized_at is not null'
  end

  def new
    @client_application = ClientApplication.new
  end

  def create
    @client_application = current_user.client_applications.build(params[:client_application])
    if @client_application.save
      flash[:notice] = "Registered the information successfully"
      redirect_to :action => "show", :id => @client_application.id
    else
      render :action => "new"
    end
  end
  
  def show
  end

  def edit
  end
  
  def update
    if @client_application.update_attributes(params[:client_application])
      flash[:notice] = "Updated the client information successfully"
      redirect_to :action => "show", :id => @client_application.id
    else
      render :action => "edit"
    end
  end

  def destroy
    begin
      ClientApplication.transaction do
        @client_application.destroy
      end
  
      flash[:notice] = "Destroyed the client application registration"
    rescue
      flash[:error] = "Could not delete the application"
    end

    redirect_to :action => "index"
  end
  
protected

  # TODO: is this really needed? @client_application is taken from the user's client application collection
  def authorise
    unless BioCatalogue::Auth.allow_user_to_claim_thing?(current_user, @client_application)
      error_to_back_or_home("You are not allowed to perform this action")
      return false
    end
    
    return true
  end
  
private
  
  def get_client_application
    unless @client_application = current_user.client_applications.find(params[:id])
      flash.now[:error] = "Wrong application id"
      raise ActiveRecord::RecordNotFound
    end
  end
  
end
