# BioCatalogue: app/controllers/services_controller.rb
#
# Copyright (c) 2008, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

class ServicesController < ApplicationController
  
  before_filter :disable_action, :only => [ :edit, :update, :destroy ]
  
  # Set the sidebar layout for certain actions.
  # Note: the set_sidebar_layout method resides in the ApplicationController.
  #before_filter :set_sidebar_layout, :only => [ :show ]
  
  # GET /services
  # GET /services.xml
  def index
    @services = Service.paginate(:page => params[:page],
                                 :order => 'created_at DESC',
                                 :include => [ :service_versions, :service_deployments ])

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @services }
      format.rss  { render :rss => @services, :layout => false}
    end
  end

  # GET /services/1
  # GET /services/1.xml
  def show
    @service = Service.find(params[:id])
    
    @latest_version = @service.latest_version
    @latest_version_instance = @latest_version.service_versionified
    
    @all_service_version_instances = @service.service_version_instances
    @all_service_types = @service.service_types
    
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @service }
    end
  end

  # GET /services/new
  # GET /services/new.xml
  def new
    @service = Service.new
    
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @service }
    end
  end

  # GET /services/1/edit
  def edit
    @service = Service.find(params[:id])
  end

  # POST /services
  # POST /services.xml
  def create
    # Creation of a Service resource is not allowed. Must be created as part of the creation of a specific service type resource.
    flash[:error] = 'Select the type of service you would like to submit first'
    respond_to do |format|
      format.html { redirect_to(new_service_url) }
      format.xml  { render :xml => '', :status => 404 }
    end
  end

  # PUT /services/1
  # PUT /services/1.xml
  def update
    @service = Service.find(params[:id])

    respond_to do |format|
      if @service.update_attributes(params[:service])
        flash[:notice] = 'Service was successfully updated.'
        format.html { redirect_to(@service) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @service.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /services/1
  # DELETE /services/1.xml
  def destroy
    @service = Service.find(params[:id])
    @service.destroy

    respond_to do |format|
      format.html { redirect_to(services_url) }
      format.xml  { head :ok }
    end
  end
 
end
