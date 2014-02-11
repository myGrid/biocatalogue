# BioCatalogue: app/controllers/stats_controller.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

class StatsController < ApplicationController

  before_filter :disable_action_for_api

  set_tab :general, :stats, :only => %w(general index)
  set_tab :metadata, :stats, :only => %w(metadata)
  set_tab :tags, :stats, :only => %w(tags)
  set_tab :search, :stats, :only => %w(search)

  before_filter :index, :only => [:general, :metadata, :tags, :search]

  def general ;  end
  def metadata ; end
  def tags ;     end
  def search ;   end

  include BioCatalogue::Stats

  def index
    @service_count = Service.count
    file = Rails.root.join('data', "#{Rails.env}_reports", 'registry_stats.yml').to_s
    if File.exists?(file)
      modified_time = File.mtime(file)
      @stats = Rails.cache.read('registry_stats')
      # Load stats from file if there's no cached copy OR
      # the stats file is newer than the stats (careful when comparing as there is
      # some time lag between generating the new stats object (which has created_at field)
      # and serialising it to the file so the 'last modified time' of the file is always a
      # couple of seconds younger than the stats object it contains so technically the file is
      # always younger than the @stats object it contains but we only want to load the file the
      # next time it is generated from a background job and not every time so we are giving it + 1 minute
      # when checking).
      if @stats.nil? || (@stats.created_at + 1.minutes) < modified_time
        @stats = YAML.load(File.open(file))
        Rails.cache.write('registry_stats', @stats)
      end
    else
      flash[:error] = "No stats report found. Please contact #{SITE_NAME} administators for help"
    end

    respond_to do |format|
      format.html {render 'stats/index'}
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