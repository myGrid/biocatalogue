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
  
  before_filter :authorise, :only => [ :destroy ]
  
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
    
    @rest_method.destroy

    # get a method under the same resource for redirection, otherwise, delete resource
    if rest_resource.rest_methods.blank?
      rest_resource.destroy
      
      # redirect to a different method from a different resource
      if rest_service.rest_resources.blank?
        redirect_url = service_url(service) + '#endpoints'
      else
        redirect_url = rest_method_url(rest_service.rest_resources[0].rest_methods[0])
      end
    else
      redirect_url = rest_method_url(rest_resource.rest_methods[0])
    end
    
    # destroy any unused parameters and representations
    destroy_unused_objects(parameter_ids, true) # is_parameter = true
    destroy_unused_objects(representation_ids, false) # is_parameter = false
    
    respond_to do |format|
      success_msg = "Endpoint <b>" + (params[:endpoint] || "") + "</b> has been deleted".squeeze(' ')
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
