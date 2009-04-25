# BioCatalogue: app/controllers/stats_controller.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

class StatsController < ApplicationController
  caches_page :index
  
  def index
    @stats = BioCatalogue::Stats.new
    
    respond_to do |format|
      format.html # index.rhtml
    end
  end
  
  def refresh
    expire_page :action => "index"
    sleep 2
    redirect_to :action => "index"
  end
end