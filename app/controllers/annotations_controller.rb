# BioCatalogue: app/controllers/annotations_controller.rb
#
# Copyright (c) 2008, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

#=====
# This extends the Annotations controller defined in the Annotations plugin.
#=====

require_dependency RAILS_ROOT + '/vendor/plugins/annotations/lib/app/controllers/annotations_controller'

class AnnotationsController < ApplicationController
  
  # Disable some of the actions provided in the controller in the plugin.
  # Note: the controller in the plugin has already disabled these actions
  # BUT throws a 404, whereas we would like to use the specific disable_action 
  # method we have set up in the main app.
  before_filter :disable_action, :only => [ :edit ]
  
  before_filter :set_no_layout, :only => [ :new_popup ]
  
  def new_popup
    # @annotatable is set in a before filter from the controller in the plugin. 
    if @annotatable.nil?
      flash[:error] = "Could not begin annotation (the thing you want to annotate is not specified or is invalid)."
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
        format.js # new_popup.html.erb
      end
    end
  end
end