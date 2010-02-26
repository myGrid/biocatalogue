# BioCatalogue: app/controllers/rest_methods_controller.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

class RestMethodsController < ApplicationController
  
  before_filter :disable_action, :only => [ :index, :show, :edit ]
  before_filter :disable_action_for_api

  before_filter :login_required
  
  before_filter :find_rest_method
  
  before_filter :authorise, :only => [ :destroy ]
  
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
    rest_resource = @rest_method.rest_resource
    service = rest_resource.rest_service.service # for redirection
    
    @rest_method.destroy

    rest_resource.destroy if rest_resource.rest_methods.blank?
    
    # destroy any unused parameters and representations
    destroy_unused_objects(parameter_ids, true) # is_parameter = true
    destroy_unused_objects(representation_ids, false) # is_parameter = false
    
    respond_to do |format|
      success_msg = "Endpoint <b>" + (params[:endpoint] || "") + "</b> has been deleted".squeeze(' ')
      flash[:notice] = success_msg
      
      format.html { redirect_to "#{service_url(service)}#endpoints" }
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
