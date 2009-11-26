# BioCatalogue: app/controllers/home_controller.rb
#
# Copyright (c) 2008, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

class HomeController < ApplicationController
  
  # GET /home
  def index
    respond_to do |format|
      format.html # index.html.erb
      format.xml { render "api/show" }
    end
  end
  
  # GET /home/latest
  def index
    respond_to do |format|
      format.html # latest.html.erb
    end
  end
  
end
