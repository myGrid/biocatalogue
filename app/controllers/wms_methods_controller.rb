# BioCatalogue: app/controllers/wms_methods_controller.rb
#
# Copyright (c) 2009-2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

class WmsMethodsController < ApplicationController

  before_filter :disable_action, :only => [ :edit ]
  before_filter :disable_action_for_api, :except => [ :index, :show, :annotations, :inputs, :outputs, :filters, :filtered_index ]

  before_filter :login_or_oauth_required, :except => [ :index, :show, :annotations, :inputs, :outputs, :filters, :filtered_index ]

  before_filter :parse_filtered_index_params, :only => :filtered_index

  before_filter :parse_current_filters, :only => [ :index, :filtered_index ]

  before_filter :get_filter_groups, :only => [ :filters ]

  before_filter :parse_sort_params, :only => [ :index, :filtered_index ]
  before_filter :find_wms_methods, :only => [ :index, :filtered_index ]

  before_filter :find_wms_method, :except => [ :index, :filters, :filtered_index ]

  before_filter :authorise, :except => [ :index, :show, :annotations, :inputs, :outputs, :filters, :filtered_index ]

  skip_before_filter :verify_authenticity_token, :only => [ :group_name_auto_complete ]

  def update_resource_path
    error_msg = @wms_method.update_resource_path(params[:new_path], current_user)

    respond_to do |format|
      if error_msg.blank?
        flash[:notice] = "Endpoint was successfully updated."
      else
        flash[:error] = error_msg
      end

      format.html { redirect_to @wms_method }
      format.xml  { head :ok }
    end
  end

  def edit_resource_path_popup
    @base_endpoint = @wms_method.wms_resource.wms_service.service.latest_deployment.endpoint

    respond_to do |format|
      format.js { render :layout => false }
    end
  end

  def update_endpoint_name
    error_msg = ""
    new_name = params[:new_name]
    new_name.chomp!
    new_name.strip!

    if @wms_method.check_endpoint_name_exists(new_name)
      error_msg = "That endpoint name is already taken for this WMS service."
    else
      unless new_name.blank?
        @wms_method.endpoint_name = new_name
        error_msg = @wms_method.save! ? "" : "Could not update the endpoint name, sorry. If this happens again, please let us know."
      end
    end

    respond_to do |format|
      if error_msg.blank?
        flash[:notice] = "The endpoint name was successfully updated."
      else
        flash[:error] = error_msg
      end

      format.html { redirect_to @wms_method }
      format.xml  { head :ok }
    end
  end

  def edit_endpoint_name_popup
    respond_to do |format|
      format.js { render :layout => false }
    end
  end

  def update
    # sanitize user input
    params[:new_name].chomp!
    params[:new_name].strip!

    do_not_proceed = params[:new_name].blank? || params[:old_name]==params[:new_name] ||
        @wms_method.check_endpoint_name_exists(params[:new_name])

    unless do_not_proceed
      @wms_method.endpoint_name = params[:new_name]
      @wms_method.save!
    end

    respond_to do |format|
      if do_not_proceed
        if params[:new_name].blank?
          flash[:error] = "An endpoint's name cannot be empty."
        elsif params[:new_name]==params[:old_name]
          flash[:notice] = "The endpoint's new name is the same as the old one; nothing has been changed."
        else
          flash[:error] = "The name you are trying to assign to this endpoint belongs to another endpoint of this service."
        end
      else
        flash[:notice] = "The endpoint has been updated"
      end
      format.html { redirect_to @wms_method }
      format.xml  { head :ok }
    end
  end

  def edit_by_popup
    respond_to do |format|
      format.js { render :layout => false }
    end
  end

  def remove_endpoint_name
    @wms_method.endpoint_name = nil
    @wms_method.save!

    respond_to do |format|
      flash[:notice] = "The endpoint's name has been deleted"

      format.html { redirect_to @wms_method }
      format.xml  { head :ok }
    end
  end

  def inline_add_endpoint_name
    # sanitize user input to make it have characters that are only fit for URIs
    params[:endpoint_name].chomp!
    params[:endpoint_name].strip!

    if @wms_method.check_endpoint_name_exists(params[:endpoint_name]) # endpoint name exists
      raise "Error - Endpoint name already taken."
    else # endpoint name does not exist
      unless params[:endpoint_name].blank?
        @wms_method.endpoint_name = params[:endpoint_name]
        @wms_method.save!
      end
    end # if else

    respond_to do |format|
      format.html { render :partial => "wms_methods/#{params[:partial]}",
                           :locals => { :wms_method => @wms_method }}
      format.js { render :partial => "wms_methods/#{params[:partial]}",
                         :locals => { :wms_method => @wms_method }}
    end # respond  
  end

  def index
    respond_to do |format|
      format.html { disable_action }
      format.xml # index.xml.builder
      format.json { render :json => BioCatalogue::Api::Json.index("wms_methods", json_api_params, @wms_methods).to_json }
      format.bljson { render :json => BioCatalogue::Api::Bljson.index("wms_methods", @wms_methods).to_json }
    end
  end

  # POST /filtered_index
  # Example Input (differs based on available filters):
  #
  # { 
  #   :filters => { 
  #     :p => [ 67, 23 ], 
  #     :tag => [ "database" ], 
  #     :c => ["Austria", "south Africa"] 
  #   }
  # }
  def filtered_index
    index
  end

  def show
    @wms_service = @wms_method.wms_resource.wms_service
    @grouped_wms_methods = @wms_service.group_all_wms_methods_from_wms_resources

    respond_to do |format|
      format.html
      format.xml  # show.xml.builder
      format.json { render :json => @wms_method.to_json }
    end
  end

  def inputs
    respond_to do |format|
      format.html { disable_action }
      format.xml  # inputs.xml.builder
      format.json { render :json => @wms_method.to_custom_json("inputs") }
    end
  end

  def outputs
    respond_to do |format|
      format.html { disable_action }
      format.xml  # outputs.xml.builder
      format.json { render :json => @wms_method.to_custom_json("outputs") }
    end
  end

  def annotations
    respond_to do |format|
      format.html { disable_action }
      format.xml { redirect_to(generate_include_filter_url(:arm, @wms_method.id, "annotations", :xml)) }
      format.json { redirect_to(generate_include_filter_url(:arm, @wms_method.id, "annotations", :json)) }
    end
  end

  def destroy
    # collect the IDs of the objects to be destroyed AFTER the method is destroyed
    # parameters
    parameter_ids = []
    @wms_method.request_parameters.each { |p| parameter_ids << p.id }

    # input representations
    representation_ids = []
    @wms_method.request_representations.each { |i_rep| representation_ids << i_rep.id }

    # output representations
    @wms_method.response_representations.each { |o_rep| representation_ids << o_rep.id }
    representation_ids.uniq!

    # destroy the method
    wms_resource = @wms_method.wms_resource # for redirection
    wms_service = wms_resource.wms_service # for redirection
    service = wms_service.service # for redirection
    deleted_endpoint = @wms_method.display_endpoint

    @wms_method.destroy

    # get a method under the same resource for redirection, otherwise, delete resource
    if wms_resource.wms_methods.blank?
      wms_resource.destroy

      # redirect to a different method from a different resource
      if wms_service.wms_resources.blank?
        redirect_url = service_url(service) + '#endpoints'
      else
        redirect_url = wms_method_url(wms_service.wms_resources.sort[0].wms_methods.sort[0])
      end
    else
      redirect_url = wms_method_url(wms_resource.wms_methods.sort[0])
    end

    # destroy any unused parameters and representations
    destroy_unused_objects(parameter_ids, true) # is_parameter = true
    destroy_unused_objects(representation_ids, false) # is_parameter = false

    respond_to do |format|
      success_msg = "Endpoint <b>".html_safe + deleted_endpoint + "</b> has been deleted".squeeze(' ').html_safe
      flash[:notice] = success_msg

      redirect_url = (service_url(wms_service.service) + '#endpoints') unless request.env["HTTP_REFERER"].include?('/wms_methods/')

      format.html { redirect_to redirect_url }
      format.xml  { head :ok }
    end
  end

  def edit_group_name_popup
    respond_to do |format|
      format.js { render :layout => false }
    end
  end

  def update_group_name
    group_name = params[:group_name].strip

    respond_to do |format|
      if !@wms_method.update_attribute(:group_name, group_name)
        flash[:error] = "Failed to set the group. (If you continue having issues with this, please contact us)"
        format.html { redirect_to @wms_method }
      else
        flash[:notice] = "Successfully set the group"
        format.html { redirect_to @wms_method }
      end
    end
  end

  def group_name_auto_complete
    @name_fragment = params[:group_name] || ''

    @results = @wms_method.wms_service.endpoint_group_names_suggestions(@name_fragment, 10)

    render :inline => "<%= auto_complete_result @results, 'name', @name_fragment %>", :layout => false
  end

  def filters
    respond_to do |format|
      format.html { disable_action }
      format.xml # filters.xml.builder
      format.json { render :json => BioCatalogue::Api::Json.filter_groups(@filter_groups).to_json }
    end
  end

  protected # ========================================

  def authorise
    unless BioCatalogue::Auth.allow_user_to_curate_thing?(current_user, @wms_method)
      error_to_back_or_home("You are not allowed to perform this action")
      return false
    end

    return true
  end

  private # ========================================

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

  def find_wms_method
    #Old Rails 2 style
    #@wms_method = WmsMethod.find(params[:id], :include => :wms_resource)
    @wms_method = WmsMethod.includes(:wms_resource).find(params[:id])
  end

  def find_wms_methods

    # Sorting

    order = 'wms_methods.created_at DESC'
    order_field = nil
    order_direction = nil

    case @sort_by
      when 'created'
        order_field = "created_at"
      when 'name'
        order_field = "endpoint_name"
    end

    case @sort_order
      when 'asc'
        order_direction = 'ASC'
      when 'desc'
        order_direction = "DESC"
    end

    unless order_field.blank? or order_direction.nil?
      order = "wms_methods.#{order_field} #{order_direction}"
    end

    # Filtering

    conditions, joins = BioCatalogue::Filtering::WmsMethods.generate_conditions_and_joins_from_filters(@current_filters, params[:q])

    if @sort_by=="name"
      joins << :wms_resource
      order = "wms_methods.endpoint_name #{order_direction}, wms_resources.path"
    end

    if self.request.format == :bljson
      joins << :wms_resource unless joins.include?(:wms_resource)

      finder_options = {
          :select => "wms_methods.id, wms_methods.endpoint_name, wms_resources.path, wms_resources.archived_at",
          :order => order,
          :conditions => conditions,
          :joins => joins
      }

      @wms_methods = ActiveRecord::Base.connection.select_all(WmsMethod.send(:construct_finder_arel, finder_options))
    else
      @wms_methods = WmsMethod.paginate(:page => @page,
                                          :per_page => @per_page,
                                          :order => order,
                                          :conditions => conditions,
                                          :joins => joins)
    end
  end

  def destroy_unused_objects(id_list, is_parameter=true)
    id_list.sort.each do |obj_id|
      if is_parameter
        # Old Rails 2 style
        #not_used = WmsMethodParameter.all(:conditions => {:wms_parameter_id => obj_id}).empty?
        not_used = WmsMethodParameter.where(:wms_parameter_id => obj_id).empty?
        WmsParameter.destroy(obj_id) if not_used
      else
        # Old Rails 2 style
        #not_used = WmsMethodRepresentation.all(:conditions => {:wms_representation_id => obj_id}).empty?
        not_used = WmsMethodRepresentation.where(:wms_representation_id => obj_id).empty?
        WmsRepresentation.destroy(obj_id) if not_used
      end
    end # id_list.each
  end

end
