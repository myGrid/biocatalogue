# BioCatalogue: app/controllers/rest_resources_controller.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

class RestResourcesController < ApplicationController
  
  before_filter :disable_action, :only => [ :index, :show, :edit ]
  before_filter :disable_action_for_api
  
  before_filter :login_required
  
  before_filter :find_rest_service

  before_filter :authorise
  
  def new_popup    
    respond_to do |format|
      format.js { render :layout => false }
    end
  end
  
  def add_new_resources
    results = @rest_service.mine_for_resources(params[:rest_resources], @rest_service.service_deployments[0].endpoint, current_user)
    
    respond_to do |format|
      unless results[:created].blank?
        flash[:notice] ||= ""
        flash[:notice] += "The following endpoints were successfully created:<br/>"
        flash[:notice] += results[:created].to_sentence
        flash[:notice] += "<br/><br/>"
      end
      
      unless results[:updated].blank?
        flash[:notice] ||= ""
        flash[:notice] += "The following endpoints already exist and have been updated:<br/>" 
        flash[:notice] += results[:updated].to_sentence
      end
      
      unless results[:error].blank?
        flash[:error] = "The following endpoints could not be added:<br/>"
        flash[:error] += results[:error].to_sentence
      end
      
      redirect_url = if request.env["HTTP_REFERER"].include?('/rest_methods/')
                       results[:last_endpoint] || :back # last endpoint
                     else
                       service_url(@rest_service.service) + '#endpoints'
                     end
      
      format.html { redirect_to redirect_url }
    end
  end
  
  
  # ========================================
  
  
  protected
  
  def authorise    
    unless BioCatalogue::Auth.allow_user_to_curate_thing?(current_user, @rest_service)
      error_to_back_or_home("You are not allowed to perform this action")
      return false
    end

    return true
  end


  # ========================================
  
  
  private
  
  def find_rest_service
    @rest_service = RestService.find(params[:rest_service_id])
  end

end
