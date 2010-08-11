# BioCatalogue: app/controllers/api_controller.rb
#
# Copyright (c) 2009-2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

class ApiController < ApplicationController
  
  def show
    respond_to do |format|
      format.html # show.html.erb
      format.xml  # show.xml.builder
      format.json { render :json => BioCatalogue::Api::Json.api_endpoint.to_json }
    end
  end
  
end