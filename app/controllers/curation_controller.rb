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
    
protected
  
  def authorise    
    unless current_user.is_curator?
      error_to_back_or_home("You are not allowed to perform this action")
      return false
    end

    return true
  end  

end