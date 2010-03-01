# BioCatalogue: app/controllers/services_controller.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

class ServicesController < ApplicationController
  
  before_filter :disable_action, :only => [ :edit, :update ]
  before_filter :disable_action_for_api, :except => [ :index, :show, :filters, :summary, :annotations, :deployments, :versions, :monitoring ]
  
  before_filter :parse_current_filters, :only => [ :index ]
  
  before_filter :parse_sort_params, :only => [ :index ]
  
  before_filter :find_services, :only => [ :index ]
  
  before_filter :find_service, :only => [ :show, :edit, :update, :destroy, :categorise, :summary, :annotations, :deployments, :versions, :monitoring ]
  
  before_filter :check_if_user_wants_to_categorise, :only => [ :show ]
  
  before_filter :setup_for_feed, :only => [ :index ]
  
  before_filter :set_page_title_suffix, :only => [ :index ]
  
  before_filter :set_listing_type, :only => [ :index ]
  
  before_filter :login_required, :only => [ :destroy ]
  before_filter :authorise, :only => [ :destroy ]
  
  # GET /services
  # GET /services.xml
  def index
    respond_to do |format|
      format.html # index.html.erb
      format.xml  # index.xml.builder
      format.atom # index.atom.builder
    end
  end

  # GET /services/1
  # GET /services/1.xml
  def show
    @latest_version = @service.latest_version
    @latest_version_instance = @latest_version.service_versionified
    @latest_deployment = @service.latest_deployment
    
    @all_service_version_instances = @service.service_version_instances
    @all_service_types = @service.service_types
    
    @soaplab_service = @service.soaplab_server
    
    respond_to do |format|
      format.html # show.html.erb
      format.xml  # show.xml.builder
    end
  end

  # GET /services/new
  # GET /services/new.xml
  def new
    @service = Service.new
    
    respond_to do |format|
      format.html # new.html.erb
      format.xml
    end
  end

  # GET /services/1/edit
  def edit
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
    respond_to do |format|
      if @service.destroy
        flash[:notice] = "Service '#{@service.name}' has been deleted"
        format.html { redirect_to services_url }
        format.xml  { head :ok }
      else
        flash[:error] = "Failed to delete service '#{@service.name}'"
        format.html { redirect_to service_url(@service) }
      end
    end
  end
  
  def categorise
    categories = [ ]
    anns = [ ]
    
    categories = params[:categories] if params.has_key?(:categories)
    
    unless categories.empty?
      anns = @service.create_annotations({ "category" => categories.split(',').compact.map{|x| x.strip}.reject{|x| x == ""} }, current_user)
    end
    
    respond_to do |format|
      flash[:notice] = if anns.empty?
        "No new categories specified"
      else
        "Categories successfully added"
      end
      format.html { redirect_to(service_url(@service)) }
    end
  end
  
  def filters
    respond_to do |format|
      format.html { disable_action }
      format.xml # filters.xml.builder
    end
  end
  
  def summary
    respond_to do |format|
      format.html { disable_action }
      format.xml # summary.xml.builder
    end
  end
  
  def annotations
    respond_to do |format|
      format.html { disable_action }
      format.xml { redirect_to(generate_include_filter_url(:as, @service.id, "annotations", :xml)) }
      format.json { render :json => @service.annotations.paginate(:page => @page, :per_page => @per_page).to_json }
    end
  end
  
  def deployments
    respond_to do |format|
      format.html { disable_action }
      format.xml # deployments.xml.builder
    end
  end
  
  def versions
    respond_to do |format|
      format.html { disable_action }
      format.xml # versions.xml.builder
    end
  end
  
  def monitoring
    respond_to do |format|
      format.html { disable_action }
      format.xml # monitoring.xml.builder
    end
  end
 
  protected
  
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
  
  def find_services
    
    # Sorting
    
    order = 'services.created_at DESC'
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
      order = "services.#{order_field} #{order_direction}"
    end
    
    # Filtering
    
    conditions, joins = BioCatalogue::Filtering::Services.generate_conditions_and_joins_from_filters(@current_filters, params[:q])
    
    @filter_message = "The services index has been filtered" unless @current_filters.blank?
    
    @services = Service.paginate(:page => @page,
                                 :per_page => @per_page,
                                 :order => order,
                                 :conditions => conditions,
                                 :joins => joins)
  end
  
  def find_service
    @service = Service.find(params[:id])
  end
  
  def check_if_user_wants_to_categorise
    if !logged_in? and params.has_key?(:categorise)
      flash.now[:notice] = "Please login or register to categorise this service"
    end
  end
  
  def setup_for_feed
    if self.request.format == :atom
      # Remove page param
      params.delete(:page)
      
      # Set feed title
      @feed_title = "BioCatalogue.org - "
      @feed_title << if (text = BioCatalogue::Filtering.filters_text_if_filters_present(@current_filters)).blank?
        "Latest Services"
      else
        "Services - #{text}"
      end
    end
  end
  
  def set_page_title_suffix
    @page_title_suffix = (BioCatalogue::Filtering.filters_text_if_filters_present(@current_filters) || "Browse All Services")
  end
  
  def set_listing_type
    @allowed_listing_types ||= [ "simple", "detailed" ]
    
    default_type = :detailed
    session_key = "services_#{action_name}_listing_type"
    
    if !params[:listing].blank? and @allowed_listing_types.include?(params[:listing].downcase)
      @listing_type = params[:listing].downcase.to_sym
      session[session_key] = params[:listing].downcase
    elsif !session[session_key].blank?
      @listing_type = session[session_key].to_sym
    else
      @listing_type = default_type
      session[session_key] = default_type.to_s 
    end
  end
  
  def authorise
    unless BioCatalogue::Auth.allow_user_to_curate_thing?(current_user, @service)
      error_to_back_or_home("You are not allowed to perform this action")
      return false
    end
    
    return true
  end
  
end
