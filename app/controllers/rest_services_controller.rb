# BioCatalogue: app/controllers/rest_services_controller.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

require 'addressable/uri'

class RestServicesController < ApplicationController
  
  before_filter :disable_action, :only => [ :index, :show, :edit, :update ]
  
  before_filter :login_required, :except => [ :index, :show ]
  
  # GET /rest_services
  # GET /rest_services.xml
  def index
    @rest_services = RestService.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @rest_services }
    end
  end

  # GET /rest_services/1
  # GET /rest_services/1.xml
  def show
    @rest_service = RestService.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @rest_service }
    end
  end

  # GET /rest_services/new
  # GET /rest_services/new.xml
  def new
    @rest_service = RestService.new
    params[:annotations] = { }

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @rest_service }
    end
  end

  # GET /rest_services/1/edit
  def edit
    @rest_service = RestService.find(params[:id])
  end

  # POST /rest_services
  # POST /rest_services.xml
  def create
    endpoint = params[:endpoint] || ""
    endpoint = Addressable::URI.parse(endpoint).normalize.to_s unless endpoint.blank?
    
    if endpoint.blank?
      flash[:error] = "Please provide a valid endpoint URL"
      respond_to do |format|
        format.html { render :action => "new" }
        format.xml  { render :xml => '', :status => 406 }
      end
    else
      # Check for a duplicate
      existing_service = RestService.check_duplicate(endpoint)
      
      if !existing_service.nil?
        # Because the service already exists, add any information provided by the user as additional annotations to the existing service.
        
        annotations_data = { }
        
        # First any name annotations...
        name_annotations = [ ]
        name_annotations << params[:rest_service][:name] unless params[:rest_service][:name].blank?
        unless params[:annotations][:name].blank?
          name_annotations << params[:annotations][:name]
          params[:annotations].delete(:name)
        end
        annotations_data["name"] = name_annotations
        
        # Then all other annotations...
        annotations_data.merge!(params[:annotations])
        
        # Now create them...  
        existing_service.latest_version.service_versionified.create_annotations(annotations_data, current_user)
        
        respond_to do |format|
          flash[:notice] = "The service you specified already exists in the BioCatalogue. See below. Any information you provided has been added to this service."
          format.html { redirect_to existing_service }
          format.xml  { render :xml => '', :status => :unprocessable_entity }
        end
      else
        # Now you can submit the service...
        @rest_service = RestService.new
        @rest_service.name = params[:rest_service][:name]
        
        respond_to do |format|
          if @rest_service.submit_service(endpoint, current_user, params[:annotations])
            flash[:notice] = 'Service was successfully submitted.'
            format.html { redirect_to(@rest_service.service(true)) }
            
            # TODO: should this return the top level Service resource or RestService? 
            format.xml  { render :xml => @rest_service, :status => :created, :location => @rest_service }
          else
            flash[:error] = 'An error has occurred with the submission. Please contact us if you need further help with this. Thank you.'
            format.html { render :action => "new" }
            format.xml  { render :xml => '', :status => 500 }
          end
        end
      end
    end
  end

  # PUT /rest_services/1
  # PUT /rest_services/1.xml
  def update
    @rest_service = RestService.find(params[:id])

    respond_to do |format|
      if @rest_service.update_attributes(params[:rest_service])
        flash[:notice] = 'RestService was successfully updated.'
        format.html { redirect_to(@rest_service) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @rest_service.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /rest_services/1
  # DELETE /rest_services/1.xml
  def destroy
    @rest_service = RestService.find(params[:id])
    @rest_service.destroy

    respond_to do |format|
      format.html { redirect_to(rest_services_url) }
      format.xml  { head :ok }
    end
  end
end
