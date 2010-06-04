# BioCatalogue: app/controllers/curation_controller.rb
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

class CurationController < ApplicationController
  
  before_filter :login_required
  
  before_filter :authorise

  def show
    # show.html.erb
  end
  
  def copy_annotations
    if request.post?
      type = params[:type]
      from = nil
      to = nil
      
      unless type.blank?
        from = type.constantize.find_by_id(params[:from_id], :include => :annotations)
        to = type.constantize.find_by_id(params[:to_id])
      end
      
      if from.nil? or to.nil?
        flash[:error] = "Either the 'from' or 'to' item doesn't exist. So could not carry on with the copy."
      else
        anns = from.copy_annotations_to(to, current_user)
        flash[:notice] = "Successfully copied over #{anns.length} annotations."
        params[:from_id] = nil
        params[:to_id] = nil
      end
    end
    
    respond_to do |format|
      format.html # copy_annotations.html.erb
    end
  end
  
  def copy_annotations_preview
    type = params[:type]
    from = nil
    to = nil
    
    unless type.blank?
      from = type.constantize.find_by_id(params[:from_id], :include => :annotations)
      to = type.constantize.find_by_id(params[:to_id])
    end
    
    unless from.nil? or to.nil?
      render :partial => "curation/copy_annotations/preview", :locals => { :type => type, :from => from, :to => to }
    else
      render :text => "<p class='error_text'>Either the 'from' or 'to' item doesn't exist</p>"
    end
  end
  
  def potential_duplicate_operations_within_service
    @operations = BioCatalogue::Curation::Reports.potential_duplicate_operations_within_service
    
    respond_to do |format|
      format.html # potential_duplicate_operations_within_service.html.erb
    end
  end
    
  
  protected
  
  
  def authorise    
    unless current_user.is_curator?
      error_to_back_or_home("You are not allowed to perform this action")
      return false
    end

    return true
  end  

end