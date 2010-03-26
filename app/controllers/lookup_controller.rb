# BioCatalogue: app/controllers/lookup_controller.rb
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

class LookupController < ApplicationController
  
  def show
    obj = BioCatalogue::Util.lookup(params)
    
    if obj
      respond_to do |format|
        format.html { redirect_to url_for_web_interface(obj) }
        format.xml  { redirect_to "#{url_for(obj)}.xml" }
        format.json  { redirect_to "#{}url_for(obj)}.json" }
      end
    else
      raise ActiveRecord::RecordNotFound.new
    end
  end
  
end
