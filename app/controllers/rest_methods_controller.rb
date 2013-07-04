# BioCatalogue: app/controllers/rest_methods_controller.rb
#
# Copyright (c) 2009-2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

class RestMethodsController < ApplicationController
  
  before_filter :disable_action, :only => [ :edit ]
  before_filter :disable_action_for_api, :except => [ :index, :show, :annotations, :inputs, :outputs, :filters, :filtered_index ]

  before_filter :login_or_oauth_required, :except => [ :index, :show, :annotations, :inputs, :outputs, :filters, :filtered_index ]

  before_filter :parse_filtered_index_params, :only => :filtered_index

  before_filter :parse_current_filters, :only => [ :index, :filtered_index ]
  
  before_filter :get_filter_groups, :only => [ :filters ]
    
  before_filter :parse_sort_params, :only => [ :index, :filtered_index ]
  before_filter :find_rest_methods, :only => [ :index, :filtered_index ]

  before_filter :find_rest_method, :except => [ :index, :filters, :filtered_index ]
  
  before_filter :authorise, :except => [ :index, :show, :annotations, :inputs, :outputs, :filters, :filtered_index ]
  
  skip_before_filter :verify_authenticity_token, :only => [ :group_name_auto_complete ]
  
  def update_resource_path
    error_msg = @rest_method.update_resource_path(params[:new_path], current_user)
    
    respond_to do |format|
      if error_msg.blank?
        flash[:notice] = "Endpoint was successfully updated."
      else
        flash[:error] = error_msg
      end
      
      format.html { redirect_to @rest_method }
      format.xml  { head :ok }
    end
  end
  
  def edit_resource_path_popup
    @base_endpoint = @rest_method.rest_resource.rest_service.service.latest_deployment.endpoint
    
    respond_to do |format|
      format.js { render :layout => false }
    end
  end

  def update_endpoint_name
    error_msg = ""
    new_name = params[:new_name]
    new_name.chomp!
    new_name.strip!

    if @rest_method.check_endpoint_name_exists(new_name)
      error_msg = "That endpoint name is already taken for this REST service."
    else
      unless new_name.blank?
        @rest_method.endpoint_name = new_name
        error_msg = @rest_method.save! ? "" : "Could not update the endpoint name, sorry. If this happens again, please let us know."
      end
    end

    respond_to do |format|
      if error_msg.blank?
        flash[:notice] = "The endpoint name was successfully updated."
      else
        flash[:error] = error_msg
      end

      format.html { redirect_to @rest_method }
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
                     @rest_method.check_endpoint_name_exists(params[:new_name])

    unless do_not_proceed
      @rest_method.endpoint_name = params[:new_name]
      @rest_method.save!
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
      format.html { redirect_to @rest_method }
      format.xml  { head :ok }
    end
  end
  
  def edit_by_popup
    respond_to do |format|
      format.js { render :layout => false }
    end
  end
  
  def remove_endpoint_name
    @rest_method.endpoint_name = nil
    @rest_method.save!
    
    respond_to do |format|
      flash[:notice] = "The endpoint's name has been deleted"

      format.html { redirect_to @rest_method }
      format.xml  { head :ok }
    end
  end
  
  def inline_add_endpoint_name
    # sanitize user input to make it have characters that are only fit for URIs
    params[:endpoint_name].chomp!
    params[:endpoint_name].strip!
    
    if @rest_method.check_endpoint_name_exists(params[:endpoint_name]) # endpoint name exists                      
      raise "Error - Endpoint name already taken."
    else # endpoint name does not exist
      unless params[:endpoint_name].blank?
        @rest_method.endpoint_name = params[:endpoint_name]
        @rest_method.save!
      end      
    end # if else
    
    respond_to do |format|
      format.html { render :partial => "rest_methods/#{params[:partial]}", 
                           :locals => { :rest_method => @rest_method }}
      format.js { render :partial => "rest_methods/#{params[:partial]}", 
                         :locals => { :rest_method => @rest_method }}
    end # respond  
  end
  
  def index
    respond_to do |format|
      format.html { disable_action }
      format.xml # index.xml.builder
      format.json { render :json => BioCatalogue::Api::Json.index("rest_methods", json_api_params, @rest_methods).to_json }
      format.bljson { render :json => BioCatalogue::Api::Bljson.index("rest_methods", @rest_methods).to_json }
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
    @rest_service = @rest_method.rest_resource.rest_service
    @grouped_rest_methods = @rest_service.group_all_rest_methods_from_rest_resources
    
    respond_to do |format|
      format.html
      format.xml  # show.xml.builder
      format.json { render :json => @rest_method.to_json }
    end
  end

  def inputs
    respond_to do |format|
      format.html { disable_action }
      format.xml  # inputs.xml.builder
      format.json { render :json => @rest_method.to_custom_json("inputs") }
    end
  end

  def outputs
    respond_to do |format|
      format.html { disable_action }
      format.xml  # outputs.xml.builder
      format.json { render :json => @rest_method.to_custom_json("outputs") }
    end
  end
  
  def annotations
    respond_to do |format|
      format.html { disable_action }
      format.xml { redirect_to(generate_include_filter_url(:arm, @rest_method.id, "annotations", :xml)) }
      format.json { redirect_to(generate_include_filter_url(:arm, @rest_method.id, "annotations", :json)) }
    end
  end
  
  def destroy
    # collect the IDs of the objects to be destroyed AFTER the method is destroyed
    # parameters
    parameter_ids = []
    @rest_method.request_parameters.each { |p| parameter_ids << p.id }
    
    # input representations
    representation_ids = []
    @rest_method.request_representations.each { |i_rep| representation_ids << i_rep.id }
    
    # output representations
    @rest_method.response_representations.each { |o_rep| representation_ids << o_rep.id }
    representation_ids.uniq!
    
    # destroy the method
    rest_resource = @rest_method.rest_resource # for redirection
    rest_service = rest_resource.rest_service # for redirection
    service = rest_service.service # for redirection
    deleted_endpoint = @rest_method.display_endpoint
    
    @rest_method.destroy

    # get a method under the same resource for redirection, otherwise, delete resource
    if rest_resource.rest_methods.blank?
      rest_resource.destroy
      
      # redirect to a different method from a different resource
      if rest_service.rest_resources.blank?
        redirect_url = service_url(service) + '#endpoints'
      else
        redirect_url = rest_method_url(rest_service.rest_resources.sort[0].rest_methods.sort[0])
      end
    else
      redirect_url = rest_method_url(rest_resource.rest_methods.sort[0])
    end
    
    # destroy any unused parameters and representations
    destroy_unused_objects(parameter_ids, true) # is_parameter = true
    destroy_unused_objects(representation_ids, false) # is_parameter = false
    
    respond_to do |format|
      success_msg = "Endpoint <b>" + deleted_endpoint + "</b> has been deleted".squeeze(' ')
      flash[:notice] = success_msg
      
      redirect_url = (service_url(rest_service.service) + '#endpoints') unless request.env["HTTP_REFERER"].include?('/rest_methods/')

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
      if !@rest_method.update_attribute(:group_name, group_name)
        flash[:error] = "Failed to set the group. (If you continue having issues with this, please contact us)"
        format.html { redirect_to @rest_method }
      else
        flash[:notice] = "Successfully set the group"
        format.html { redirect_to @rest_method }
      end
    end
  end
  
  def group_name_auto_complete
    @name_fragment = params[:group_name] || ''
    
    @results = @rest_method.rest_service.endpoint_group_names_suggestions(@name_fragment, 10)
                                    
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
    unless BioCatalogue::Auth.allow_user_to_curate_thing?(current_user, @rest_method)
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

  def find_rest_method
    @rest_method = RestMethod.find(params[:id], :include => :rest_resource)
  end
  
  def find_rest_methods
    
    # Sorting
    
    order = 'rest_methods.created_at DESC'
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
      order = "rest_methods.#{order_field} #{order_direction}"
    end
    
    # Filtering
    
    conditions, joins = BioCatalogue::Filtering::RestMethods.generate_conditions_and_joins_from_filters(@current_filters, params[:q])
    
    if @sort_by=="name"
      joins << :rest_resource
      order = "rest_methods.endpoint_name #{order_direction}, rest_resources.path"
    end
    
    if self.request.format == :bljson
      joins << :rest_resource unless joins.include?(:rest_resource)
      
      finder_options = {
        :select => "rest_methods.id, rest_methods.endpoint_name, rest_resources.path, rest_resources.archived_at",
        :order => order,
        :conditions => conditions,
        :joins => joins
      }
      
      @rest_methods = ActiveRecord::Base.connection.select_all(RestMethod.send(:construct_finder_sql, finder_options))
    else
      @rest_methods = RestMethod.paginate(:page => @page,
                                          :per_page => @per_page,
                                          :order => order,
                                          :conditions => conditions,
                                          :joins => joins)
    end
  end
  
  def destroy_unused_objects(id_list, is_parameter=true)
    id_list.sort.each do |obj_id|
      if is_parameter
        not_used = RestMethodParameter.all(:conditions => {:rest_parameter_id => obj_id}).empty?
        RestParameter.destroy(obj_id) if not_used
      else
        not_used = RestMethodRepresentation.all(:conditions => {:rest_representation_id => obj_id}).empty?
        RestRepresentation.destroy(obj_id) if not_used      
      end
    end # id_list.each
  end
  
end
