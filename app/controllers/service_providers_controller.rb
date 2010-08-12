# BioCatalogue: app/controllers/service_providers_controller.rb
#
# Copyright (c) 2008-2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

class ServiceProvidersController < ApplicationController
  
  before_filter :disable_action, :only => [ :new, :edit, :create, :destroy ]
  before_filter :disable_action_for_api, :except => [ :index, :show, :annotations, :annotations_by, :services ]
  
  skip_before_filter :verify_authenticity_token, :only => [ :auto_complete ]

  before_filter :parse_sort_params, :only => [ :index ]
  
  before_filter :find_service_providers, :only => [ :index ]
  
  before_filter :find_service_provider, :only => [ :show, :edit, :update, :destroy, :annotations, :annotations_by, :edit_by_popup ]
  
  before_filter :authorise, :only => [ :edit_by_popup, :update ]
  
  # GET /service_providers
  # GET /service_providers.xml
  def index
    respond_to do |format|
      format.html # index.html.erb
      format.xml  # index.xml.builder
      format.json { render :json => BioCatalogue::Api::Json.index("service_providers", json_api_params, @service_providers, true).to_json }
    end
  end

  # GET /service_providers/1
  # GET /service_providers/1.xml
  def show
    @provider_hostnames = @service_provider.service_provider_hostnames
    
    unless is_api_request?
      @provider_services = @service_provider.services.paginate(:page => params[:page], 
                                                               :order => "created_at DESC")
    end
    
    respond_to do |format|
      format.html # show.html.erb
      format.xml  # show.xml.builder
      format.json { render :json => @service_provider.to_json }
    end
  end
  
  def annotations
    respond_to do |format|
      format.html { disable_action }
      format.xml { redirect_to(generate_include_filter_url(:asp, @service_provider.id, "annotations", :xml)) }
      format.json { redirect_to(generate_include_filter_url(:asp, @service_provider.id, "annotations", :json)) }
    end
  end
  
  def annotations_by
    respond_to do |format|
      format.html { disable_action }
      format.xml { redirect_to(generate_include_filter_url(:sosp, @service_provider.id, "annotations", :xml)) }
      format.json { redirect_to(generate_include_filter_url(:sosp, @service_provider.id, "annotations", :json)) }
    end
  end
  
  def services
    respond_to do |format|
      format.html { disable_action }
      format.xml { redirect_to(generate_include_filter_url(:p, params[:id], "services", :xml)) }
      format.json { redirect_to(generate_include_filter_url(:p, params[:id], "services", :json)) }
    end
  end

  def edit_by_popup
    respond_to do |format|
      format.js { render :layout => false }
    end
  end

  def update
    name = params[:name] || ""
    name.chomp!
    name.strip!
    
    not_changed = name.downcase == @service_provider.name.downcase
    
    success = true
    
    if name.blank? || not_changed # complain
      flash[:error] = (not_changed ? "The new name cannot be the same as the old one" : "Please provide a valid provider name")
      success = false
    else # do MERGE OR RENAME
      existing_provider = ServiceProvider.find_by_name(name)
      current_sp_name = @service_provider.name
      
      if existing_provider.nil? # do RENAME
        @service_provider.name = name
        @service_provider.save!
      
        flash[:notice] = "The Service Provider's name has been updated"
      elsif @service_provider.merge_into(existing_provider) # do MERGE
        flash[:notice] = "Service Provider '#{current_sp_name}' was successfully merged into '#{existing_provider.name}'"
        @service_provider = existing_provider
      else # complain
        flash[:error] = "An error occured while merging this Service Provider into #{existing_provider.name}.<br/>" +
                        "Please contact us if this error persists."
        success = false
      end
      
    end # if name.blank? || not_changed
    
    if success
      respond_to do |format|
        format.html { redirect_to @service_provider }
        format.xml  { head :ok }
      end      
    else # failure
      respond_to do |format|
        format.html { redirect_to @service_provider }
        format.xml  { render :xml => '', :status => 406 }
      end
    end # if success
  end

  def auto_complete
    @name_fragment = params[:name] || ''
    
    @results = ServiceProvider.find(:all , 
                                    :conditions => "name like '%" + @name_fragment.downcase + "%'")
                                    
    render :inline => "<%= auto_complete_result @results, 'name', @name_fragment %>", :layout => false
  end

  protected
  
  def parse_sort_params
    sort_by_allowed = [ "created", "name" ]
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
  
  def find_service_providers
    
    # Sorting
    
    order = 'service_providers.created_at DESC'
    order_field = nil
    order_direction = nil
    
    case @sort_by
      when 'created'
        order_field = "created_at"
      when 'name'
        order_field = "name"
    end
    
    case @sort_order
      when 'asc'
        order_direction = 'ASC'
      when 'desc'
        order_direction = "DESC"
    end
    
    unless order_field.blank? or order_direction.nil?
      order = "service_providers.#{order_field} #{order_direction}"
    end
    
    @service_providers = ServiceProvider.paginate(:page => @page,
                                 :per_page => @per_page,
                                 :order => order)
  end
  
  def find_service_provider
    @service_provider = ServiceProvider.find(params[:id])
  end
  
  def authorise
    unless BioCatalogue::Auth.allow_user_to_curate_thing?(current_user, @service_provider)
      error_to_back_or_home("You are not allowed to perform this action")
      return false
    end
    
    return true
  end

end
