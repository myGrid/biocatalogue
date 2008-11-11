# BioCatalogue: app/controllers/annotations_controller.rb
#
# Copyright (c) 2008, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

class AnnotationsController < ApplicationController
  before_filter :login_required
  
  def add_annotation
    annotatable_type = params[:annotation][:annotatable_type]
    annotatable_id = params[:annotation][:annotatable_id]
    
    # Get the object that you want to annotate
    annotatable = Annotation.find_annotatable(annotatable_type, annotatable_id)

    # Create an an annotation with the user submitted content
    annotation = Annotation.new(params[:annotation])
    # Assign this comment to the logged in user
    annotation.source_id = session[:user_id]

    # Add the annotation
    annotatable.annotations << annotation

    #redirect_to :action => annotatable_type.downcase,
    #  :id => annotatable_id
    redirect_to annotatable
  end
end
