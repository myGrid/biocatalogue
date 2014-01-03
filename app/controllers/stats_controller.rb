# BioCatalogue: app/controllers/stats_controller.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

class StatsController < ApplicationController
  
  before_filter :disable_action_for_api
  
  def index

    # Do not attempt to generate stats if there are no services in the Catalogue
    @service_count = Service.count

    @stats = BioCatalogue::Stats.get_last_stats unless @service_count == 0

    registry_stats_file = Rails.root.join('data', "#{Rails.env}-registry_stats.yml").to_s
    @stats = YAML.load(File.open(registry_stats_file)) unless !File.exists?(registry_stats_file)

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