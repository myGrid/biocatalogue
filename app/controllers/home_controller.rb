# BioCatalogue: app/controllers/home_controller.rb
#
# Copyright (c) 2008, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

class HomeController < ApplicationController
  
  before_filter :disable_action_for_api, :except => [ :index ]
  
  def index
    respond_to do |format|
      format.html # index.html.erb
      format.xml { redirect_to api_url(:format => :xml), :status => 303 }
    end
  end
  
  def latest
    respond_to do |format|
      format.html # latest.html.erb
    end
  end
  
end
