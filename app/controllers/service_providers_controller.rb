# BioCatalogue: app/controllers/service_providers_controller.rb
#
# Copyright (c) 2008-2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

class ServiceProvidersController < ApplicationController
  
  before_filter :disable_action, :only => [ :new, :create, :edit, :update, :destroy ]
  before_filter :disable_action_for_api, :except => [ :index, :show, :annotations, :annotations_by, :services ]
  
  before_filter :parse_sort_params, :only => [ :index ]
  
  before_filter :find_service_providers, :only => [ :index ]
  
  before_filter :find_service_provider, :only => [ :show, :edit, :update, :destroy, :annotations, :annotations_by ]
  
  # GET /service_providers
  # GET /service_providers.xml
  def index
    respond_to do |format|
      format.html # index.html.erb
      format.xml  # index.xml.builder
    end
  end

  # GET /service_providers/1
  # GET /service_providers/1.xml
  def show
    unless is_api_request?
      @provider_services = @service_provider.services.paginate(:page => params[:page], 
                                                               :order => "created_at DESC")
    end
    
    respond_to do |format|
      format.html # show.html.erb
      format.xml  # show.xml.builder
    end
  end
  
  def annotations
    respond_to do |format|
      format.html { disable_action }
      format.xml { redirect_to(generate_include_filter_url(:asp, @service_provider.id, "annotations", :xml)) }
      format.json { render :json => BioCatalogue::Annotations.group_by_attribute_names(@service_provider.annotations).values.flatten.to_json }
    end
  end
  
  def annotations_by
    respond_to do |format|
      format.html { disable_action }
      format.xml { redirect_to(generate_include_filter_url(:sosp, @service_provider.id, "annotations", :xml)) }
      format.json { render :json => BioCatalogue::Annotations.group_by_attribute_names(@service_provider.annotations_by).values.flatten.to_json }
    end
  end
  
  def services
    respond_to do |format|
      format.html { disable_action }
      format.xml { redirect_to(generate_include_filter_url(:p, params[:id], "services", :xml)) }
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
  
  def find_service_providers
    
    # Sorting
    
    order = 'service_providers.created_at DESC'
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
      order = "service_providers.#{order_field} #{order_direction}"
    end
    
    @service_providers = ServiceProvider.paginate(:page => @page,
                                 :per_page => @per_page,
                                 :order => order)
  end
  
  def find_service_provider
    @service_provider = ServiceProvider.find(params[:id])
  end
  
end
