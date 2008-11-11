# BioCatalogue: app/controllers/service_deployments_controller.rb
#
# Copyright (c) 2008, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

class ServiceDeploymentsController < ApplicationController
  # GET /service_deployments
  # GET /service_deployments.xml
  def index
    @service_deployments = ServiceDeployment.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @service_deployments }
    end
  end

  # GET /service_deployments/1
  # GET /service_deployments/1.xml
  def show
    @service_deployment = ServiceDeployment.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @service_deployment }
    end
  end

  # GET /service_deployments/new
  # GET /service_deployments/new.xml
  def new
    @service_deployment = ServiceDeployment.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @service_deployment }
    end
  end

  # GET /service_deployments/1/edit
  def edit
    @service_deployment = ServiceDeployment.find(params[:id])
  end

  # POST /service_deployments
  # POST /service_deployments.xml
  def create
    @service_deployment = ServiceDeployment.new(params[:service_deployment])

    respond_to do |format|
      if @service_deployment.save
        flash[:notice] = 'ServiceDeployment was successfully created.'
        format.html { redirect_to(@service_deployment) }
        format.xml  { render :xml => @service_deployment, :status => :created, :location => @service_deployment }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @service_deployment.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /service_deployments/1
  # PUT /service_deployments/1.xml
  def update
    @service_deployment = ServiceDeployment.find(params[:id])

    respond_to do |format|
      if @service_deployment.update_attributes(params[:service_deployment])
        flash[:notice] = 'ServiceDeployment was successfully updated.'
        format.html { redirect_to(@service_deployment) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @service_deployment.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /service_deployments/1
  # DELETE /service_deployments/1.xml
  def destroy
    @service_deployment = ServiceDeployment.find(params[:id])
    @service_deployment.destroy

    respond_to do |format|
      format.html { redirect_to(service_deployments_url) }
      format.xml  { head :ok }
    end
  end
end
