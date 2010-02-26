# BioCatalogue: app/controllers/lookup_controller.rb
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

class LookupController < ApplicationController
  
  def show
    obj = BioCatalogue::Util.lookup(params)
    
    if obj
      redirect_to obj
    else
      raise ActiveRecord::RecordNotFound.new
    end
  end
  
end
