class LatestController < ApplicationController
  before_filter :load_feed

  set_tab :activity, :latest, :only => %w(activity show)
  set_tab :contributors, :latest, :only => %w(contributors)
  set_tab :services, :latest, :only => %w(services)
  set_tab :monitoring, :latest, :only => %w(monitoring)

  before_filter :show, :only => [:activity, :services, :contributors, :monitoring]

  def load_feed
    unless is_api_request?
      ActivityLog.benchmark "ActivityLog entries for /home/latest", :level => :info, :silence => true do
        @activity_logs_main = BioCatalogue::ActivityFeeds.activity_logs_for(:home, :style => :detailed)
        @activity_logs_monitoring = BioCatalogue::ActivityFeeds.activity_logs_for(:monitoring, :style => :detailed)
      end
    end
  end

  def show
    respond_to do |format|
      format.html {render 'home/latest'}
    end
  end

  def activity ; end
  def services ;  end
  def contributors ;   end
  def monitoring ;  end

end