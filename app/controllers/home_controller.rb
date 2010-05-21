# BioCatalogue: app/controllers/home_controller.rb
#
# Copyright (c) 2008-2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

class HomeController < ApplicationController
  
  before_filter :disable_action_for_api, :except => [ :index ]
  
  def index
    unless is_api_request?
      ActivityLog.benchmark "ActivityLog entries for /home", Logger::INFO, false do
        @activity_logs_main = BioCatalogue::ActivityFeeds.activity_logs_for(:home, :style => :simple)
        @activity_logs_monitoring = BioCatalogue::ActivityFeeds.activity_logs_for(:monitoring, :style => :simple, :items_limit => 5)
      end
    end
    
    respond_to do |format|
      format.html # index.html.erb
      format.xml { redirect_to api_url(:format => :xml), :status => 303 }
    end
  end
  
  def latest
    unless is_api_request?
      ActivityLog.benchmark "ActivityLog entries for /home/latest", Logger::INFO, false do
        @activity_logs_main = BioCatalogue::ActivityFeeds.activity_logs_for(:home, :style => :detailed)
        @activity_logs_monitoring = BioCatalogue::ActivityFeeds.activity_logs_for(:monitoring, :style => :detailed)
      end
    end
    
    respond_to do |format|
      format.html # latest.html.erb
    end
  end
  
end
