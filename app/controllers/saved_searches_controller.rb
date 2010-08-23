# BioCatalogue: app/controllers/saved_searches_controller.rb
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

class SavedSearchesController < ApplicationController

  before_filter :disable_action, :except => [ :show ]
  before_filter :disable_action_for_api, :except => [ :show ]
  
  before_filter :login_or_oauth_required
      
  before_filter :find_saved_search, :only => :show
  
  before_filter :authorise

  def show
    respond_to do |format|
      format.html { disable_action }
      format.xml  # show.xml.builder
      format.json { render :json => @saved_search.to_json }
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
