# BioCatalogue: app/controllers/rest_services_controller.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

require 'addressable/uri'

class RestServicesController < ApplicationController
  
  before_filter :disable_action, :only => [ :index, :edit, :update, :destroy ]
  before_filter :disable_action_for_api, :except => [ :show, :annotations, :deployments ]
  
  before_filter :login_required, :except => [ :index, :show, :annotations, :deployments ]

  before_filter :find_service_deployment, :only => [ :edit_base_endpoint_by_popup, :update_base_endpoint ]
  
  before_filter :authorise, :only => [ :edit_base_endpoint_by_popup, :update_base_endpoint ]
  
  before_filter :find_rest_service, :only => [ :show, :annotations, :deployments ]
  
  # GET /rest_services
  # GET /rest_services.xml
  def index
    #@rest_services = RestService.find(:all)

    respond_to do |format|
#      format.html { disable_action }
#      format.xml  { render :xml => @rest_services }
    end
  end

  # GET /rest_services/1
  # GET /rest_services/1.xml
  def show
    respond_to do |format|
      format.html { disable_action }
      format.xml  # show.xml.builder
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

  # POST /rest_services
  # POST /rest_services.xml
  def create
    endpoint = params[:endpoint] || ""
    endpoint.chomp!
    endpoint.strip!
    endpoint = "http://" + endpoint unless endpoint.blank? or endpoint.starts_with?("http://") or endpoint.starts_with?("https://")
    endpoint = Addressable::URI.parse(endpoint).normalize.to_s unless endpoint.blank?
    
    if endpoint.blank?
      flash.now[:error] = "Please provide a valid endpoint URL"
      respond_to do |format|
        format.html { render :action => "new" }
        format.xml  { render :xml => '', :status => 406 }
      end
    else
      # Check for a duplicate
      existing_service = RestService.check_duplicate(endpoint)
      
      if !existing_service.nil?
        # Because the service already exists, add any information provided by the user as additional annotations to the existing service.

        annotations_data = params[:annotations].clone
        
        # Special case for alternative name annotations...
        
        name_annotations = [ ]
        
        main_name = params[:rest_service][:name]
        name_annotations << params[:rest_service][:name] if !main_name.blank? && !existing_service.name.downcase.eql?(main_name.downcase)
        
        name_annotations << annotations_data[:alternative_name] if !annotations_data[:alternative_name].blank? and !existing_service.name.downcase.eql?(annotations_data[:alternative_name].downcase)
        
        annotations_data[:alternative_name] = name_annotations
        
        # Now create them...  
        existing_service.latest_version.service_versionified.process_annotations_data(annotations_data, current_user)
        
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
          if @rest_service.submit_service(endpoint, current_user, params[:annotations].dup)
            success_msg = 'Service was successfully submitted.'
#            success_msg += "  You may now add endpoints via the Endpoints tab."
            
            flash[:notice] = success_msg
            format.html { redirect_to(@rest_service.service(true)) }
            
            # TODO: should this return the top level Service resource or RestService? 
            format.xml  { render :xml => @rest_service, :status => :created, :location => @rest_service }
          else
            err_text = "An error has occurred with the submission.<br/>" +
              "Please <a href='/contact'>contact us</a> if you need assistance with this."
            flash.now[:error] = err_text
            format.html { render :action => "new" }
            format.xml  { render :xml => '', :status => 500 }
          end
        end
      end
    end
  end

  def edit_base_endpoint_by_popup    
    respond_to do |format|
      format.js { render :layout => false }
    end
  end

  def update_base_endpoint
    endpoint = params[:new_endpoint] || ""
    endpoint.chomp!
    endpoint.strip!
    endpoint = "http://" + endpoint unless endpoint.blank? or endpoint.starts_with?("http://") or endpoint.starts_with?("https://")
    
    endpoint = Addressable::URI.parse(endpoint).normalize.to_s unless endpoint.blank?
    
    not_changed = params[:new_endpoint] == @service_deployment.endpoint
    exists = !RestService.check_duplicate(endpoint).nil?
    
    if endpoint.blank? || not_changed || exists
      flash[:error] = (not_changed || exists ?
                      "The endpoint you are trying to submit already exists in the system" :
                      "Please provide a valid endpoint URL")
      
      respond_to do |format|
        format.html { redirect_to @service_deployment.service }
        format.xml  { render :xml => '', :status => 406 }
      end
    else
      @service_deployment.endpoint = endpoint
      @service_deployment.save!
    
      respond_to do |format|
        format.html { redirect_to @service_deployment.service }
        format.xml  { head :ok }
      end
    end

  end

  def annotations
    respond_to do |format|
      format.html { disable_action }
      format.xml { redirect_to(generate_include_filter_url(:ars, @rest_service.id, "annotations", :xml)) }
      format.json { render :json => BioCatalogue::Annotations.group_by_attribute_names(@rest_service.annotations).values.flatten.to_json }
    end
  end
  
  def deployments
    respond_to do |format|
      format.html { disable_action }
      format.xml  # deployments.xml.builder
    end
  end
  
  
  # ========================================
  
  
  protected
  
  def find_rest_service
    @rest_service = RestService.find(params[:id])
  end
  
  def authorise
    unless BioCatalogue::Auth.allow_user_to_curate_thing?(current_user, @service_deployment)
      error_to_back_or_home("You are not allowed to perform this action")
      return false
    end
    
    return true
  end

  
  # ========================================
  
  
  private
  
  def find_service_deployment
    @service_deployment = ServiceDeployment.find(params[:service_deployment_id])
  end

end
