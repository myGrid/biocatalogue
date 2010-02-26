# BioCatalogue: app/controllers/rest_parameters_controller.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

class RestParametersController < ApplicationController
  
  before_filter :disable_action, :only => [ :index, :show, :edit ]
  before_filter :disable_action_for_api

  before_filter :login_required
  
  before_filter :find_rest_method, :only => [ :new_popup, :add_new_parameters ]
  before_filter :find_rest_parameter, :except => [ :new_popup, :add_new_parameters ]
  
  before_filter :authorise, :except => [ :new_popup, :add_new_parameters ]

  def update_constraint    
    do_not_proceed = params[:new_constraint].blank? || 
                     params[:old_constraint]==params[:new_constraint] || 
                     @rest_parameter.constrained_options.include?(params[:new_constraint])

    unless do_not_proceed
      @rest_parameter.constrained_options.delete(params[:old_constraint])
      @rest_parameter.constrained_options << params[:new_constraint]
      @rest_parameter.save!
    end
    
    respond_to do |format|
      if do_not_proceed
        flash[:error] = "An error occured while trying to update constraint for parameter <b>#{@rest_parameter.name}</b>"
      else
        flash[:notice] = "Constraint for parameter <b>" + @rest_parameter.name.gsub("UNIQUE_TO_METHOD_#{params[:rest_method_id]}-", '') + "</b> has been updated"
      end
      format.html { redirect_to get_redirect_url }
      format.xml  { head :ok }
    end
  end

  def edit_constraint_popup
    @old_constraint = params[:constraint]
    
    respond_to do |format|
      format.js { render :layout => false }
    end
  end
  
  def remove_constraint
    @rest_parameter.constrained_options.delete(params[:constraint])
    @rest_parameter.save!
    
    respond_to do |format|
      flash[:notice] = "Constraint has been deleted from parameter <b>" + @rest_parameter.name.gsub("UNIQUE_TO_METHOD_#{params[:rest_method_id]}-", '') + "</b>"

      format.html { redirect_to get_redirect_url }
      format.xml  { head :ok }
    end
  end
  
  def inline_add_constraints
    do_not_proceed = params[:constraint].blank? || 
                     @rest_parameter.constrained_options.include?(params[:constraint])
    
    unless do_not_proceed
      @rest_parameter.constrained_options << params[:constraint]
      @rest_parameter.save!
    end
    
    respond_to do |format|
      format.html { render :partial => "annotations/#{params[:partial]}", 
                           :locals => { :parameter => @rest_parameter,
                                        :rest_method_id => params[:rest_method_id]} }
      format.js { render :partial => "annotations/#{params[:partial]}", 
                         :locals => { :parameter => @rest_parameter, 
                                      :rest_method_id => params[:rest_method_id] } } 
    end
  end

  def new_popup    
    respond_to do |format|
      format.js { render :layout => false }
    end
  end

  def add_new_parameters    
    resource = @rest_method.rest_resource # for redirection
    service = resource.rest_service.service # for redirection
    
    count = @rest_method.add_parameters(params[:rest_parameters], current_user)
    
    respond_to do |format|
      flash[:notice] = "#{count} new parameter" + (count==1 ? ' was':'s were') + ' added'
      format.html { redirect_to "#{service_url(service)}#rest_method_#{@rest_method.id}" }
    end
  end
  
  def localise_globalise_parameter
    url_to_redirect_to = get_redirect_url()

    param_name, param_default_value = @rest_parameter.name, @rest_parameter.default_value
  
    # destroy map
    destroy_method_param_map() # this is the map for the parameter being linked/unlinked

    is_not_used = RestMethodParameter.find(:all, :conditions => {:rest_parameter_id => @rest_parameter.id}).empty?
    @rest_parameter.destroy if is_not_used
    
    # make unique or generic
    associated_method = RestMethod.find(params[:rest_method_id])    
    if params[:make_unique] # make the param unique to the method
      unique_param = "UNIQUE_TO_METHOD_" + params[:rest_method_id] + '-' + param_name + '=' + param_default_value
      associated_method.add_parameters(unique_param, current_user, :make_unique => true)
    else # use an already existing param OR create one as needed
      generic_param = param_name.gsub("UNIQUE_TO_METHOD_#{params[:rest_method_id]}-", '') + '=' + param_default_value
      associated_method.add_parameters(generic_param, current_user)
    end

    respond_to do |format|
      if params[:make_unique]
        success_msg = "Parameter <b>#{param_name}</b> now has a copy unique for endpoint <b>" + (params[:endpoint] || "") + "</b>"
      else
        success_msg = "Parameter <b>" + param_name.gsub("UNIQUE_TO_METHOD_#{params[:rest_method_id]}-", '') + "</b> for endpoint <b>" + (params[:endpoint] || "") + "</b> is now global"
      end
      flash[:notice] = success_msg.squeeze(' ')

      format.html { redirect_to url_to_redirect_to }
      format.xml  { head :ok }
    end
  end
  
  def make_optional_or_mandatory
    @rest_parameter.required = !@rest_parameter.required
    @rest_parameter.save!
    
    respond_to do |format|
      flash[:notice] = "Parameter <b>" + @rest_parameter.name.gsub("UNIQUE_TO_METHOD_#{params[:rest_method_id]}-", '') + "</b> is now " + (@rest_parameter.required ? 'mandatory':'optional')
      format.html { redirect_to get_redirect_url }
      format.xml  { head :ok }
    end
  end
  
  def destroy
    success_msg = "Parameter <b>" + @rest_parameter.name.gsub("UNIQUE_TO_METHOD_#{params[:rest_method_id]}-", '') + "</b> has been deleted"

    url_to_redirect_to = get_redirect_url()
    
    destroy_method_param_map()
    
    is_not_used = RestMethodParameter.find(:all, :conditions => {:rest_parameter_id => @rest_parameter.id}).empty?
    @rest_parameter.destroy if is_not_used
        
    respond_to do |format|
      flash[:notice] = success_msg
      format.html { redirect_to url_to_redirect_to }
      format.xml  { head :ok }
    end
  end
  
  
  # ========================================
  
  
  protected
  
  def authorise
    unless BioCatalogue::Auth.allow_user_to_curate_thing?(current_user, @rest_parameter, :rest_method => RestMethod.find(params[:rest_method_id]))
      error_to_back_or_home("You are not allowed to perform this action")
      return false
    end

    return true
  end


  # ========================================
  
  
  private
  
  def get_redirect_url()
    method_param_map = RestMethodParameter.find(:first, 
                                                :conditions => {:rest_parameter_id => @rest_parameter.id, 
                                                                :rest_method_id => params[:rest_method_id]})

    rest_method = RestMethod.find(params[:rest_method_id])
    resource = rest_method.rest_resource
    service = resource.rest_service.service
        
    return "#{service_url(service)}#rest_method_#{params[:rest_method_id]}"
  end
  
  def destroy_method_param_map() # USES params[:rest_method_id] and @rest_parameter.id
    method_param_map = RestMethodParameter.find(:first, 
                                                :conditions => {:rest_parameter_id => @rest_parameter.id, 
                                                                :rest_method_id => params[:rest_method_id]})
    method_param_map.destroy
  end
  
  def find_rest_parameter
    @rest_parameter = RestParameter.find(params[:id])
  end
  
  def find_rest_method
    @rest_method = RestMethod.find(params[:rest_method_id])
  end

end
