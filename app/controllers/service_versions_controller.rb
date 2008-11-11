# BioCatalogue: app/controllers/service_versions_controller.rb
#
# Copyright (c) 2008, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

class ServiceVersionsController < ApplicationController
  # GET /service_versions
  # GET /service_versions.xml
  def index
    @service_versions = ServiceVersion.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @service_versions }
    end
  end

  # GET /service_versions/1
  # GET /service_versions/1.xml
  def show
    @service_version = ServiceVersion.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @service_version }
    end
  end

  # GET /service_versions/new
  # GET /service_versions/new.xml
  def new
    @service_version = ServiceVersion.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @service_version }
    end
  end

  # GET /service_versions/1/edit
  def edit
    @service_version = ServiceVersion.find(params[:id])
  end

  # POST /service_versions
  # POST /service_versions.xml
  def create
    @service_version = ServiceVersion.new(params[:service_version])

    respond_to do |format|
      if @service_version.save
        flash[:notice] = 'ServiceVersion was successfully created.'
        format.html { redirect_to(@service_version) }
        format.xml  { render :xml => @service_version, :status => :created, :location => @service_version }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @service_version.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /service_versions/1
  # PUT /service_versions/1.xml
  def update
    @service_version = ServiceVersion.find(params[:id])

    respond_to do |format|
      if @service_version.update_attributes(params[:service_version])
        flash[:notice] = 'ServiceVersion was successfully updated.'
        format.html { redirect_to(@service_version) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @service_version.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /service_versions/1
  # DELETE /service_versions/1.xml
  def destroy
    @service_version = ServiceVersion.find(params[:id])
    @service_version.destroy

    respond_to do |format|
      format.html { redirect_to(service_versions_url) }
      format.xml  { head :ok }
    end
  end
end
