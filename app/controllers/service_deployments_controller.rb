# BioCatalogue: app/controllers/service_deployments_controller.rb
#
# Copyright (c) 2008, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

class ServiceDeploymentsController < ApplicationController
  
  before_filter :disable_action, :only => [ :index, :new, :create, :edit, :update, :destroy ]
  before_filter :disable_action_for_api, :except => [ :show, :annotations ]
  
  before_filter :find_service_deployment, :only => [ :show, :annotations, :edit_location_by_popup, :update_location ]
  
  # GET /service_deployments/1
  # GET /service_deployments/1.xml
  def show
    respond_to do |format|
      format.html { disable_action }
      format.xml  # show.xml.builder
      format.json { render :json => @service_deployment.to_json }
    end
  end

  def edit_location_by_popup
    respond_to do |format|
      format.js { render :layout => false }
    end
  end

  def update_location
    respond_to do |format|
      if @service_deployment.update_attributes(params[:service_deployment])
        flash[:notice] = "Successfully updated service location to #{@service_deployment.location}."
      else
        flash[:error] = "Could not update the service location. Please contact us if this keeps failing."
      end

      format.html { redirect_to @service_deployment.service }
    end
  end

  def annotations
    respond_to do |format|
      format.html { disable_action }
      format.xml { redirect_to(generate_include_filter_url(:asd, @service_deployment.id, "annotations", :xml)) }
      format.json { redirect_to(generate_include_filter_url(:asd, @service_deployment.id, "annotations", :json)) }
    end
  end
  
  protected
  
  def find_service_deployment
    @service_deployment = ServiceDeployment.find(params[:id])
  end
  
end
