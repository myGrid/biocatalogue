# BioCatalogue: app/controllers/rest_services_controller.rb
#
# Copyright (c) 2009-2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

require 'addressable/uri'

class RestServicesController < ApplicationController
  
  before_filter :disable_action, :only => [ :edit, :update, :destroy, :endpoints ]
  before_filter :disable_action_for_api, :except => [ :index, :show, :create, :annotations, :deployments, :resources ]
  
  before_filter :login_or_oauth_required, :except => [ :index, :show, :annotations, :deployments, :resources ]

  before_filter :find_service_deployment, :only => [ :edit_base_endpoint_by_popup, :update_base_endpoint ]
  
  before_filter :authorise, :only => [ :edit_base_endpoint_by_popup, :update_base_endpoint ]
  
  before_filter :find_rest_service, :only => [ :show, :annotations, :deployments, :resources ]
  
  before_filter :parse_sort_params, :only => :index
  before_filter :find_rest_services, :only => :index

  oauth_authorize :create
  
  # GET /rest_services
  # GET /rest_services.xml
  def index
    respond_to do |format|
      format.html { disable_action }
      format.xml # index.xml.builder
      format.json { render :json => BioCatalogue::Api::Json.index("rest_services", json_api_params, @rest_services).to_json }
    end
  end

  # GET /rest_services/1
  # GET /rest_services/1.xml
  def show
    respond_to do |format|
      format.html { disable_action }
      format.xml  # show.xml.builder
      format.json { render :json => @rest_service.to_json }
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
  # POST /rest_services.json
  # Example Input:
  #
  #  {
  #   "rest_service" => {
  #      "name" => "official name"
  #    },
  #    "endpoint" => "http://www.example.com",
  #    "annotations" => {
  #      "documentation_url" => "doc",
  #      "alternative_names" => ["alt1", "alt2", "alt3"],
  #      "tags" => ["t1", "t3", "t2"],
  #      "description" => "desc",
  #      "categories" => [ <list of category URIs> ]
  #    }
  #  }
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
        # TODO: implement format.xml  { render :xml => '', :status => 406 }
        format.json { render :json => { :error => { :message => "Please provide a valid endpoint URL", :status => 406 }}.to_json }
      end
    else
      if is_api_request? # Sanitize for API Request
        category_ids = []
        
        params[:annotations] ||= {}
        params[:annotations][:categories] ||= []
        
        params[:annotations][:categories].compact.each { |cat| category_ids << BioCatalogue::Api.object_for_uri(cat.to_s).id if BioCatalogue::Api.object_for_uri(cat.to_s) }
        params[:annotations][:categories] = category_ids
      end

      # Check for a duplicate
      existing_service = RestService.check_duplicate(endpoint)
      
      if !existing_service.nil?
        # Because the service already exists, add any information provided by the user as additional annotations to the existing service.

        annotations_data = params[:annotations].clone
        
        # Special case for alternative name annotations...        
        main_name = params[:rest_service][:name]
        annotations_data[:alternative_name] = params[:rest_service][:name] if !main_name.blank? && !existing_service.name.downcase.eql?(main_name.downcase)
        
        # Now create them...  
        existing_service.latest_version.service_versionified.process_annotations_data(annotations_data, current_user)
        
        respond_to do |format|
          flash[:notice] = "The service you specified already exists in the BioCatalogue. See below. Any information you provided has been added to this service."
          format.html { redirect_to existing_service }
          # TODO: implement format.xml  { render :xml => '', :status => :unprocessable_entity }
          format.json { 
            render :json => { 
              :success => { 
                :message => "The REST service you specified already exists in the BioCatalogue. Any information you provided has been added to this service.", 
                :resource => service_url(existing_service),
                :status => 202
              }
            }.to_json 
          }
        end
      else
        has_missing_elements = params[:rest_service].blank? || params[:rest_service][:name].blank? || params[:rest_service][:name].chomp.strip.blank?
        if is_api_request? && has_missing_elements
          respond_to do |format|
            format.html { disable_action }
            format.json { render :json => { :error => { :message => "Please provide a valid name for the REST Service you wish to create.", :status => 406 }}.to_json }
          end
        else
          # Now you can submit the service...
          @rest_service = RestService.new
          @rest_service.name = params[:rest_service][:name].chomp.strip
          
          respond_to do |format|
            if @rest_service.submit_service(endpoint, current_user, params[:annotations].clone)
              success_msg = 'Service was successfully submitted.'
              success_msg += "<br/>You may now add endpoints via the Endpoints tab."
              
              flash[:notice] = success_msg
              format.html { redirect_to(@rest_service.service(true)) }
              # TODO: implement format.xml  { render :xml => @rest_service, :status => :created, :location => @rest_service }
              # format.json { render :json => @rest_service.service(true).to_json }
              format.json { 
                render :json => { 
                  :success => { 
                    :message => "The REST Service '#{@rest_service.name}' has been successfully submitted.", 
                    :resource => service_url(@rest_service.service(true)),
                    :status => 201
                  }
                }.to_json 
              }
            else
              err_text = "An error has occurred with the submission.<br/>" +
                "Please <a href='/contact'>contact us</a> if you need assistance with this."
              flash.now[:error] = err_text
              format.html { render :action => "new" }
              # TODO: implement format.xml  { render :xml => '', :status => 500 }
              format.json { 
                render :json => { :error => { :message => "An error has occurred with the submission.  Please contact us if need assistance with this.", :status => 500 }}.to_json 
              }
            end
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
    
      flash[:notice] = "The base URL has been successfully changed"
      
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
      format.json { redirect_to(generate_include_filter_url(:ars, @rest_service.id, "annotations", :json)) }
    end
  end
  
  def resources
    respond_to do |format|
      format.html { disable_action }
      format.xml  # deployments.xml.builder
      format.json { render :json => @rest_service.to_custom_json("rest_resources") }
    end
  end

  def deployments
    respond_to do |format|
      format.html { disable_action }
      format.xml  # deployments.xml.builder
      format.json { render :json => @rest_service.to_custom_json("deployments") }
    end
  end
  
  def endpoints
    respond_to do |format|
      format.html { disable_action }
      format.xml  # endpoints.xml.builder
      format.json { render :json => @rest_service.to_custom_json("endpoints") }
    end
  end
  
protected # ========================================
  
  def find_rest_service
    @rest_service = RestService.find(params[:id], :include => :service)
  end
    
  def authorise
    unless BioCatalogue::Auth.allow_user_to_curate_thing?(current_user, @service_deployment)
      error_to_back_or_home("You are not allowed to perform this action")
      return false
    end
    
    return true
  end
  
  def parse_sort_params
    sort_by_allowed = [ "created" ]
    @sort_by = if params[:sort_by] && sort_by_allowed.include?(params[:sort_by].downcase)
      params[:sort_by].downcase
    else
      "created"
    end
    
    sort_order_allowed = [ "asc", "desc" ]
    @sort_order = if params[:sort_order] && sort_order_allowed.include?(params[:sort_order].downcase)
      params[:sort_order].downcase
    else
      "desc"
    end
  end

  def find_service_deployment
    @service_deployment = ServiceDeployment.find(params[:service_deployment_id])
  end

  def find_rest_services

    # Sorting
    
    order = 'rest_services.created_at DESC'
    order_field = nil
    order_direction = nil
    
    case @sort_by
      when 'created'
        order_field = "created_at"
    end
    
    case @sort_order
      when 'asc'
        order_direction = 'ASC'
      when 'desc'
        order_direction = "DESC"
    end
    
    unless order_field.blank? or order_direction.nil?
      order = "rest_services.#{order_field} #{order_direction}"
    end
    
    @rest_services = RestService.paginate(:page => @page,
                                          :per_page => @per_page,
                                          :order => order)
  end

end
