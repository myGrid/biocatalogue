# BioCatalogue: app/controllers/services_controller.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

class ServicesController < ApplicationController
  
  before_filter :disable_action, :only => [ :edit, :update, :destroy ]
  
  before_filter :parse_current_filters, :only => [ :index ]
  
  before_filter :find_services, :only => [ :index ]
  
  before_filter :find_service, :only => [ :show, :edit, :update, :destroy, :categorise ]
  
  before_filter :check_if_user_wants_to_categorise, :only => [ :show ]
  
  before_filter :setup_for_feed, :only => [ :index ]
  
  # GET /services
  # GET /services.xml
  def index
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @services }
      format.atom
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
    @service.destroy

    respond_to do |format|
      format.html { redirect_to(services_url) }
      format.xml  { head :ok }
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
 
  protected
  
  def find_services
    
    # TODO: move most of the logic below into the new lib/filtering.rb library.
    
    # Sorting
    
    order = 'services.created_at DESC'
    
    if !params[:sortby].blank? and !params[:sortorder].blank?
      order_field = nil
      order_direction = nil
      
      case params[:sortby].downcase
        when 'created'
          order_field = "services.created_at"
        when 'updated'
          order_field = "services.updated_at"
      end
      
      case params[:sortorder].downcase
        when 'asc'
          order_direction = 'ASC'
        when 'desc'
          order_direction = "DESC"
      end
      
      unless order_field.blank? or order_direction.nil?
        order = "#{order_field} #{order_direction}"
      end
    end
    
    # Filters
    
    conditions, joins = BioCatalogue::Filtering.generate_conditions_and_joins_from_filters(@current_filters, params[:q])
    
    @filter_message = "The services index has been filtered" unless @current_filters.blank?
    
    # For atom feed we need to show 20 items instead
    page_size = (params[:format] == 'atom' ? 20 : PAGE_ITEMS_SIZE)
    
    @services = Service.paginate(:page => params[:page],
                                 :per_page => page_size,
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
    if params[:format] == 'atom'
      # Remove page param
      params.delete(:page)
      
      # Set page title
      t = "BioCatalogue.org - "
      
      if !@current_filters.blank?
        t << "Services - Filtered Results"
      else
        t << "Latest Services"
      end
      
      @feed_title = t
    end
  end
 
end
