# BioCatalogue: app/controllers/registries_controller.rb
#
# Copyright (c) 2009-2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

class RegistriesController < ApplicationController
  
  before_filter :disable_action, :only => [ :new, :edit, :create, :update, :destroy ]
  before_filter :disable_action_for_api, :except => [ :index, :show, :annotations_by, :services ]
  
  before_filter :parse_sort_params, :only => [ :index ]
  
  before_filter :find_registries, :only => [ :index ]
  
  before_filter :find_registry, :only => [ :show, :annotations_by ]
  
  # GET /registries
  # GET /registries.xml
  def index
    respond_to do |format|
      format.html # index.html.erb
      format.xml  # index.xml.builder
      format.json { render :json => BioCatalogue::Api::Json.index("registries", json_api_params, @registries).to_json }
    end
  end

  # GET /registries/1
  # GET /registries/1.xml
  def show
    unless is_api_request?
      @registrys_services = @registry.services.paginate(:page => params[:page],
                                                        :order => "created_at DESC")
    end
    
    respond_to do |format|
      format.html # show.html.erb
      format.xml  # show.xml.builder
      format.json { render :json => @registry.to_json }
    end
  end
  
  def annotations_by
    respond_to do |format|
      format.html { disable_action }
      format.xml { redirect_to(generate_include_filter_url(:sor, @registry.id, "annotations", :xml)) }
      format.json { redirect_to(generate_include_filter_url(:sor, @registry.id, "annotations", :json)) }
    end
  end
  
  def services
    respond_to do |format|
      format.html { disable_action }
      format.xml { redirect_to(generate_include_filter_url(:sr, params[:id], "services", :xml)) }
      format.json { redirect_to(generate_include_filter_url(:sr, params[:id], "services", :json)) }
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
  
  def find_registries
    
    # Sorting
    
    order = 'registries.created_at DESC'
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
      order = "registries.#{order_field} #{order_direction}"
    end
    
    @registries = Registry.paginate(:page => @page,
                           :per_page => @per_page,
                           :order => order)
  
  end
  
  def find_registry
    @registry = Registry.find(params[:id])
  end

end
