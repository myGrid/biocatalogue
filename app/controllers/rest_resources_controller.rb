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

  def new_popup    
    respond_to do |format|
      format.js { render :layout => false }
    end
  end
  
  def add_new_resources
    count = @rest_service.mine_for_resources(params[:rest_resources], @rest_service.service_deployments[0].endpoint, current_user)
    
    respond_to do |format|
      flash[:notice] = "#{count} new " + (count==1 ? 'endpoint was':'endpoints were') + ' added'
      
      redirect_url = if request.env["HTTP_REFERER"].include?('/rest_methods/')
                       request.env["HTTP_REFERER"] # redirect_to :back
                     else
                       service_url(@rest_service.service) + '#endpoints'
                     end
      
      format.html { redirect_to redirect_url }
    end
  end
  
  
  # ========================================
  
  
  private
  
  def find_rest_service
    @rest_service = RestService.find(params[:rest_service_id])
  end

end
