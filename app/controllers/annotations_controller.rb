# BioCatalogue: app/controllers/annotations_controller.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

#=====
# This extends the Annotations controller defined in the Annotations plugin.
#=====

require_dependency RAILS_ROOT + '/vendor/plugins/annotations/lib/app/controllers/annotations_controller'

class AnnotationsController < ApplicationController
  
  # Disable some of the actions provided in the controller in the plugin.
  before_filter :disable_action, :only => [ :index, :show, :edit ]
  
  before_filter :add_use_tab_cookie_to_session, :only => [ :create, :create_multiple, :update, :destroy, :set_as_field ]
  
  before_filter :login_required, :only => [ :new, :create, :edit, :update, :destroy, :edit_popup, :create_inline, :change_attribute ]
  
  before_filter :find_annotation, :only => [ :show, :edit, :update, :destroy, :edit_popup, :download, :change_attribute ]
  
  before_filter :find_annotatable, :only => [ :new, :create, :new_popup, :create_inline ]
  
  skip_before_filter :authorise_action
  before_filter :authorise, :only =>  [ :edit, :edit_popup, :update, :destroy, :change_attribute ]
  
  def new_popup
    if @annotatable.nil?
      flash[:error] = "Could not begin annotation (the thing you want to annotate is not specified or is invalid). Please contact the BioCatalogue folks."
      respond_to do |format|
        format.js {
          render :update do |page|
            page.redirect_to root_url
          end
        }
      end
    else
      @annotation = Annotation.new
    
      # Populate from query string values provided in the URL (if provided)
      @annotation.annotatable_type = params[:annotatable_type]
      @annotation.annotatable_id = params[:annotatable_id]
      @annotation.attribute_name = params[:attribute_name]
      
      @multiple = !params[:multiple].nil? && (params[:multiple].downcase == "true")
      @separator = params[:separator].nil? ? '' : params[:separator]
  
      respond_to do |format|
        format.js { render :layout => false }
      end
    end
  end
  
  def edit_popup
    respond_to do |format|
      format.js { render :layout => false }
    end
  end
  
  def create_inline
    # Set source as the current logged in user
    params[:annotation][:source_type] = current_user.class.name
    params[:annotation][:source_id] = current_user.id
    
    # Do we create multiple annotations or a single annotation?
    if params[:multiple]
      success, annotations, errors = Annotation.create_multiple(params[:annotation], params[:separator])
    else
      annotation = Annotation.new(params[:annotation])
      annotation.annotatable = @annotatable
      annotation.save!    # This will raise an exception if it fails
    end
    
    respond_to do |format|
      format.html { redirect_to @annotatable }
      format.js { render :partial => "annotations/#{params[:partial]}", :locals => { :annotatable => @annotatable } } 
    end
  end
  
  def download
    send_data(@annotation.value, :type => "text/plain", :disposition => 'inline')
  end
  
  def change_attribute
    attribs_allowed_to_be_changed = %w( alternative_name )
    attribs_allowed_to_be_changed_to = %w( display_name )
    
    new_attrib = params[:new_attribute]
    
    # Check that the attributes are allowed...
    if attribs_allowed_to_be_changed.include?(@annotation.attribute_name.downcase) and
       attribs_allowed_to_be_changed_to.include?(new_attrib.try(:downcase))
    
      # Authorise and carry on... 
      if BioCatalogue::Auth.allow_user_to_curate_thing?(current_user, @annotation.annotatable)
        @annotation.attribute_name = new_attrib
        
        if @annotation.save
          respond_to do |format|
            flash[:notice] = "#{new_attrib.humanize} successfully updated"
            format.html { redirect_to :back }
          end
        else
          error_to_back_or_home "Sorry, something went wrong. Please try again. If this problem persists we would appreciate it if you contacted us."
        end
      else
        error_to_back_or_home "You are not allowed to do that!"
      end
      
    end
  end
  
  protected
  
  def authorise
    allowed = false
    case action_name.downcase
      when "edit", "update", "edit_popup"
        allowed = mine?(@annotation)
      else
        allowed = BioCatalogue::Auth.allow_user_to_curate_thing?(current_user, @annotation)
    end
    
    unless allowed
      error_to_back_or_home('You are not allowed to perform this action', true)
    end
    
    return allowed
  end
  
end