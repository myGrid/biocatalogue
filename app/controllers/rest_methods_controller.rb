# BioCatalogue: app/controllers/rest_methods_controller.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

class RestMethodsController < ApplicationController
  
  before_filter :disable_action, :only => [ :index, :edit ]
  before_filter :disable_action_for_api

  before_filter :login_required, :except => [ :show ]
  
  before_filter :find_rest_method
  
  before_filter :authorise, :except => [ :show ]
    
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
  
  def show
    @rest_service = @rest_method.rest_resource.rest_service
    @base_endpoint = @rest_service.service.latest_deployment.endpoint
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
  
  
  # ========================================
  
  
  protected

  def authorise
    unless BioCatalogue::Auth.allow_user_to_curate_thing?(current_user, @rest_method)
      error_to_back_or_home("You are not allowed to perform this action")
      return false
    end
    
    return true
  end


  # ========================================
  
  
  private
  
  def find_rest_method
    @rest_method = RestMethod.find(params[:id])
  end
  
  def destroy_unused_objects(id_list, is_parameter=true)
    id_list.sort.each do |obj_id|
      if is_parameter
        not_used = RestMethodParameter.find(:all, :conditions => {:rest_parameter_id => obj_id}).empty?
        RestParameter.destroy(obj_id) if not_used
      else
        not_used = RestMethodRepresentation.find(:all, :conditions => {:rest_representation_id => obj_id}).empty?
        RestRepresentation.destroy(obj_id) if not_used      
      end
    end # id_list.each
  end
end
