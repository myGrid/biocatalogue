# BioCatalogue: app/controllers/saved_searches_controller.rb
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

class SavedSearchesController < ApplicationController

  before_filter :disable_action, :except => [ :show, :create ]
  
  before_filter :login_or_oauth_required
      
  before_filter :find_saved_search, :only => :show
  
  before_filter :authorise, :except => :create

  oauth_authorize :create, :show

  def show
    respond_to do |format|
      format.html { disable_action }
      format.xml  # show.xml.builder
      format.json { render :json => @saved_search.to_json }
    end
  end

  # POST /saved_searches
  # Example Input (application/json):
  #
  def create
    has_missing_elements = params[:name].blank? || 
                           (params[:query].blank? && params[:all_scopes].nil?) || 
                           ![ true, false ].include?(params[:all_scopes])
      
    if has_missing_elements
      respond_to do |format|
        format.html { disable_action }
        # TODO: implement format.xml  { render :xml => '', :status => 406 }
        format.json { render :json => { :error => "Please provide a valid search definition" }.to_json, :status => 406  }
      end
    else
      @saved_search = SavedSearch.new
      
      if @saved_search.submit(params.merge(:user_id => current_user.id))
        respond_to do |format|
          format.html { disable_action }
          # TODO: implement format.xml  { render :xml => @saved_search, :status => :created, :location => @saved_search }
          format.json { 
            render :json => { 
              :success => { 
                :message => "The search '#{@saved_search.name}' has been successfully saved.", 
                :resource => saved_search_url(@saved_search)
              }
            }.to_json, :status => 201
          }
        end
      else # submission failed
        respond_to do |format|
          format.html { disable_action }
          # TODO: implement format.xml  { render :xml => '', :status => 500 }
            format.json { 
              error_list = []
              @saved_search.errors.to_a.each { |e| error_list << {e[0] => e[1]} } 
              render :json => { :errors => error_list }.to_json,  :status => 500
            }
        end
      end
    end
  end

protected

  def authorise
    unless BioCatalogue::Auth.allow_user_to_claim_thing?(current_user, @saved_search)
      error_to_back_or_home("You are not allowed to perform this action")
      return false
    end
    
    return true
  end
  
private
  
  def find_saved_search
    @saved_search = SavedSearch.find(params[:id])
  end

end
