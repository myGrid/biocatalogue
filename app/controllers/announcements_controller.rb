# BioCatalogue: app/controllers/announcements_controller.rb
#
# Copyright (c) 2008-2009, University of Manchester, The European Bioinformatics
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

class AnnouncementsController < ApplicationController
  
  before_filter :disable_action_for_api, :except => [ :index ]
  
  before_filter :login_or_oauth_required, :except => [ :show, :index ]
  before_filter :authorise, :except => [ :show, :index ]
  
  before_filter :find_announcement, :only => [ :show, :edit, :update, :destroy ]
  
  before_filter :find_announcements, :only => [ :index ]
  
  before_filter :setup_for_feed, :only => [ :index ]
  
  def index
    respond_to do |format|
      format.html # index.html.erb
      format.xml  # index.xml.builder
      format.atom # index.atom.builder
    end
  end

  def show
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @announcement }
    end
  end

  def new
    @announcement = Announcement.new
    
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @announcement }
    end
  end

  def create
    params[:announcement][:user_id] = current_user.id
    
    @announcement = Announcement.new(params[:announcement])

    respond_to do |format|
      if @announcement.save
        flash[:notice] = 'Announcement was successfully created'
        format.html { redirect_to(@announcement) }
        format.xml  { render :xml => @announcement, :status => :created, :location => @announcement }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @announcement.errors, :status => :unprocessable_entity }
      end
    end
  end

  def edit
  end

  def update
    respond_to do |format|
      if @announcement.update_attributes(params[:announcement])
        flash[:notice] = 'Announcement was successfully updated'
        format.html { redirect_to(@announcement) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @announcement.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @announcement.destroy
    
    flash[:notice] = "Announcement deleted"
    
    respond_to do |format|
      format.html { redirect_to(announcements_url) }
      format.xml  { head :ok }
    end
  end
  
  protected
  
  def find_announcement
    @announcement = Announcement.find(params[:id])
  end
  
  def find_announcements
    @announcements = Announcement.paginate(:page => params[:page],
                                           :order => 'created_at DESC')
  end
  
  def setup_for_feed
    if self.request.format == :atom
      # Remove page param
      params.delete(:page)
      
      # Set page title
      @feed_title = "BioCatalogue.org - Site Announcements"
    end
  end
  
  def authorise
    unless BioCatalogue::Auth.allow_user_to_curate_thing?(current_user, :announcements)
      error_to_back_or_home("You are not allowed to perform this action")
      return false
    end
    
    return true
  end
  
end
