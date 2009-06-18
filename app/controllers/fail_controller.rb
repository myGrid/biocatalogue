# BioCatalogue: app/controllers/fail_controller.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

class FailController < ApplicationController
  
  # GET /fail/:http_code
  def index
    case params[:http_code]
      when "404"
        raise ActionController::RoutingError, "test"
      when "500"
        x = nil
        x.hello_world
    end
    
    respond_to do |format|
      format.html # index.html.erb
    end
  end
  
end
