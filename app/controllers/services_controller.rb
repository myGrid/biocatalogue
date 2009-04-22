# BioCatalogue: app/controllers/services_controller.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

class ServicesController < ApplicationController
  
  before_filter :disable_action, :only => [ :edit, :update, :destroy ]
  
  before_filter :find_services, :only => [ :index ]
  
  before_filter :find_service, :only => [ :show, :edit, :update, :destroy ]
  
  # Set the sidebar layout for certain actions.
  # Note: the set_sidebar_layout method resides in the ApplicationController.
  #before_filter :set_sidebar_layout, :only => [ :show ]
  
  # GET /services
  # GET /services.xml
  def index
    @tags = BioCatalogue::Tags.get_tags(30)
    
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
    
    # Filter conditions
    
    conditions = { }
    joins = [ ]
    
    unless params[:filter].blank?
      params[:filter].each do |filter_type, filter_values|
        unless filter_values.blank?
          case filter_type.to_s.downcase
            when 'type'
              service_types = [ ]
              filter_values.each do |f|
                # TODO: strip this out into a more generic mapping table (prob in config or lib)
                case f.downcase
                  when 'soap'
                    service_types << 'SoapService'
                    @filter_message = "The services index has been filtered to only show SOAP based services."
                  when 'rest'
                    service_types << 'RestService'
                    @filter_message = "The services index has been filtered to only show REST based services."
                end
              end
              
              unless service_types.blank?
                conditions[:service_versions] = { :service_versionified_type => service_types }
                joins << :service_versions
              end
            when 'prov'
              provider = filter_values
              
              unless provider.blank?
                conditions[:service_deployments] = { :service_providers => { :name => provider } }
                joins << [ { :service_deployments => :provider } ]
                
                @filter_message = "The services index has been filtered to only show services from the provider: '#{provider}'"
              end
          end
        end
      end
    end
    
    #flash.now[:notice] = "The services index has been filtered. Please see below." unless conditions.blank? or joins.blank?
    
    @services = Service.paginate(:page => params[:page],
                                 :order => order,
                                 :conditions => conditions,
                                 :joins => joins)
  end
  
  def find_service
    @service = Service.find(params[:id])
  end
 
end
