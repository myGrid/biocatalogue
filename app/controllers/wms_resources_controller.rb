# BioCatalogue: app/controllers/wms_resources_controller.rb
#
# Copyright (c) 2009-2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

class WmsResourcesController < ApplicationController

  before_filter :disable_action, :only => [ :edit ]
  before_filter :disable_action_for_api, :except => [ :show, :index, :annotations, :methods ]

  before_filter :login_or_oauth_required, :except => [ :show, :index, :annotations, :methods ]

  before_filter :find_wms_service, :except => [ :show, :index, :annotations, :methods ]

  before_filter :find_wms_resource, :only => [ :show, :annotations, :methods ]

  before_filter :parse_sort_params, :only => :index
  before_filter :find_wms_resources, :only => :index

  before_filter :authorise, :except => [ :show, :index, :annotations, :methods ]

  def new_popup
    respond_to do |format|
      format.js { render :layout => false }
    end
  end

  def add_new_resources
    results = @wms_service.mine_for_resources(params[:wms_resources], @wms_service.service_deployments[0].endpoint, current_user)

    respond_to do |format|
      unless results[:created].blank?
        flash[:notice] ||= "".html_safe
        flash[:notice] += "The following endpoints were successfully created:<br/>".html_safe
        flash[:notice] += results[:created].to_sentence.html_safe
        flash[:notice] += "<br/><br/>".html_safe
      end

      unless results[:updated].blank?
        flash[:notice] ||= "".html_safe
        flash[:notice] += "The following endpoints already exist and have been updated where possible:<br/>".html_safe
        flash[:notice] += results[:updated].to_sentence.html_safe
      end

      unless results[:error].blank?
        flash[:error] = "The following endpoints could not be added:<br/>".html_safe
        flash[:error] += results[:error].to_sentence.html_safe
      end

      redirect_url = if request.env["HTTP_REFERER"].include?('/wms_methods/')
                       results[:last_endpoint] || :back # last endpoint
                     else
                       service_url(@wms_service.service) + '#endpoints'
                     end

      format.html { redirect_to redirect_url }
    end
  end

  def index
    respond_to do |format|
      format.html { disable_action }
      format.xml # index.xml.builder
      format.json { render :json => BioCatalogue::Api::Json.index("wms_resources", json_api_params, @wms_resources).to_json }
    end
  end

  def show
    respond_to do |format|
      format.html { redirect_to url_for_web_interface(@wms_resource) }
      format.xml  # show.xml.builder
      format.json { render :json => @wms_resource.to_json }
    end
  end

  def annotations
    respond_to do |format|
      format.html { disable_action }
      format.xml { redirect_to(generate_include_filter_url(:arres, @wms_resource.id, "annotations", :xml)) }
      format.json { redirect_to(generate_include_filter_url(:arres, @wms_resource.id, "annotations", :json)) }
    end
  end

  def methods
    respond_to do |format|
      format.html { redirect_to url_for_web_interface(@wms_resource) }
      format.xml  # methods.xml.builder
      format.json { render :json => @wms_resource.to_json }
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
    unless BioCatalogue::Auth.allow_user_to_curate_thing?(current_user, @wms_service.service)
      error_to_back_or_home("You are not allowed to perform this action.")
      return false
    end

    return true
  end

  private # ========================================

  def find_wms_service
    @wms_service = WmsService.find(params[:wms_service_id])
  end

  def find_wms_resource
    @wms_resource = WmsResource.find(params[:id], :include => :wms_service)
  end

  def find_wms_resources

    # Sorting

    order = 'wms_resources.created_at DESC'
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
      order = "wms_resources.#{order_field} #{order_direction}"
    end

    @wms_resources = WmsResource.paginate(:page => @page,
                                            :per_page => @per_page,
                                            :order => order)
  end

end
