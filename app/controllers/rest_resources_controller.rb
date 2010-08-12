# BioCatalogue: app/controllers/rest_resources_controller.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

class RestResourcesController < ApplicationController
  
  before_filter :disable_action, :only => [ :edit ]
  before_filter :disable_action_for_api, :except => [ :show, :index, :annotations, :methods ]
  
  before_filter :login_or_oauth_required, :except => [ :show, :index, :annotations, :methods ]
  
  before_filter :find_rest_service, :except => [ :show, :index, :annotations, :methods ]
  
  before_filter :find_rest_resource, :only => [ :show, :annotations, :methods ]

  before_filter :parse_sort_params, :only => :index
  before_filter :find_rest_resources, :only => :index

  before_filter :authorise, :except => [ :show, :index, :annotations, :methods ]
  
  def new_popup    
    respond_to do |format|
      format.js { render :layout => false }
    end
  end
  
  def add_new_resources
    results = @rest_service.mine_for_resources(params[:rest_resources], @rest_service.service_deployments[0].endpoint, current_user)
    
    respond_to do |format|
      unless results[:created].blank?
        flash[:notice] ||= ""
        flash[:notice] += "The following endpoints were successfully created:<br/>"
        flash[:notice] += results[:created].to_sentence
        flash[:notice] += "<br/><br/>"
      end
      
      unless results[:updated].blank?
        flash[:notice] ||= ""
        flash[:notice] += "The following endpoints already exist and have been updated where possible:<br/>" 
        flash[:notice] += results[:updated].to_sentence
      end
      
      unless results[:error].blank?
        flash[:error] = "The following endpoints could not be added:<br/>"
        flash[:error] += results[:error].to_sentence
      end
      
      redirect_url = if request.env["HTTP_REFERER"].include?('/rest_methods/')
                       results[:last_endpoint] || :back # last endpoint
                     else
                       service_url(@rest_service.service) + '#endpoints'
                     end
      
      format.html { redirect_to redirect_url }
    end
  end
  
  def index
    respond_to do |format|
      format.html { disable_action }
      format.xml # index.xml.builder
      format.json { render :json => BioCatalogue::Api::Json.index("rest_resources", json_api_params, @rest_resources, true).to_json }
    end
  end

  def show
    respond_to do |format|
      format.html { redirect_to url_for_web_interface(@rest_resource) }
      format.xml  # show.xml.builder
      format.json { render :json => @rest_resource.to_json }
    end
  end
  
  def annotations
    respond_to do |format|
      format.html { disable_action }
      format.xml { redirect_to(generate_include_filter_url(:arres, @rest_resource.id, "annotations", :xml)) }
      format.json { redirect_to(generate_include_filter_url(:arres, @rest_resource.id, "annotations", :json)) }
    end
  end

  def methods
    respond_to do |format|
      format.html { redirect_to url_for_web_interface(@rest_resource) }
      format.xml  # methods.xml.builder
      format.json { render :json => @rest_resource.to_json }
    end
  end

  
protected # ========================================
  
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

  def authorise    
    unless BioCatalogue::Auth.allow_user_to_curate_thing?(current_user, @rest_service.service)
      error_to_back_or_home("You are not allowed to perform this action")
      return false
    end

    return true
  end
  
private # ========================================
  
  def find_rest_service
    @rest_service = RestService.find(params[:rest_service_id])
  end
  
  def find_rest_resource
    @rest_resource = RestResource.find(params[:id], :include => :rest_service)
  end
  
  def find_rest_resources
    
    # Sorting
    
    order = 'rest_resources.created_at DESC'
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
      order = "rest_resources.#{order_field} #{order_direction}"
    end
    
    @rest_resources = RestResource.paginate(:page => @page,
                                            :per_page => @per_page,
                                            :order => order)
  end

end
