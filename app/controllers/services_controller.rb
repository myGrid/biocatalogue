# BioCatalogue: app/controllers/services_controller.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

class ServicesController < ApplicationController
  
  before_filter :disable_action, :only => [ :edit, :update, :destroy ]
  
  before_filter :find_services, :only => [ :index ]
  
  before_filter :find_service, :only => [ :show, :edit, :update, :destroy ]
  
  before_filter :validate_and_setup_search, :only => [ :search ]
  
  before_filter :log_search, :only => [ :search ]
  
  # Set the sidebar layout for certain actions.
  # Note: the set_sidebar_layout method resides in the ApplicationController.
  #before_filter :set_sidebar_layout, :only => [ :show ]
  
  # GET /services
  # GET /services.xml
  def index
    @tags = BioCatalogue::Tags.get_tags(100)
    
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @services }
      format.rss  { render :rss => @services, :layout => false}
    end
  end

  # GET /services/1
  # GET /services/1.xml
  def show
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
  
  # DELETE /services/search
  # DELETE /services/search.xml
  def search
    unless @query.blank?
      begin
        @results = BioCatalogue::Search.search(@query, @type)
      rescue Exception => ex
        flash.now[:error] = "Search failed. Possible bad search term. Please report this if it continues for other searches."
        logger.error("ERROR: search failed for query: '#{@query}'. Exception:")
        logger.error(ex.message)
        logger.error(ex.backtrace.join("\n"))
      end
      
      session[:last_search] = request.url if @results and @results.total > 0
    end
    
    respond_to do |format|
      format.html # search.html.erb
      format.xml { set_no_layout } # search.xml.builder
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
    
    conditions, joins = BioCatalogue::Filtering.generate_conditions_and_joins_from_filters(params)
    
    @filter_message = "The services index has been filtered using the selected filters on the left..." unless conditions.blank? or joins.blank?
    
    @services = Service.paginate(:page => params[:page],
                                 :order => order,
                                 :conditions => conditions,
                                 :joins => joins)
  end
  
  def find_service
    @service = Service.find(params[:id])
  end
 
end
