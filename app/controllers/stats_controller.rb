# BioCatalogue: app/controllers/stats_controller.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

class StatsController < ApplicationController
  
  def index
    @stats = BioCatalogue::Stats.get_last_stats
    
    respond_to do |format|
      format.html
    end
  end
  
  def refresh
    BioCatalogue::Stats.submit_job_to_refresh_stats
    
    respond_to do |format|
      flash[:notice] = "Latest statistics are now being generated. Please refresh this page after a few minutes..."
      format.html { redirect_to stats_index_url }
    end
  end
  
end