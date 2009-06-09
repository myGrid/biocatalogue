# BioCatalogue: app/controllers/search_controller.rb
#
# Copyright (c) 2008, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

class SearchController < ApplicationController
  
  before_filter :add_use_tab_cookie_to_session, :only => [ :show ]
  
  before_filter :validate_and_setup_search, :only => [ :show ]
  
  after_filter :remember_search, :only => [ :show ]
  
  def show
    
    if @query.blank?

      respond_to do |format|
        format.html # show.html.erb
        format.xml { render :layout => false  } # show.xml.builder
      end
      
    else
      
      # Either peform an 'all' search or redirect to the appropriate type's search action
      if BioCatalogue::Search::ALL_TYPES_SYNONYMS.include?(@type)
        
        # Only log search now (since if redirected to the individual type's controller then it is logged there).
        log_search
        
        begin
          @results = BioCatalogue::Search.search_all(@query)
        rescue Exception => ex
          flash.now[:error] = "Search failed. Possible bad search term. Please report this if it continues for other searches."
          logger.error("Search failed for query: '#{@query}'. Exception:")
          logger.error(ex.message)
          logger.error(ex.backtrace.join("\n"))
        end
        
        respond_to do |format|
          format.html # show.html.erb
          format.xml { render :layout => false } # show.xml.builder
        end
        
      else
        redirect_to :controller => @type, :action => "search", :q => @query
      end
    
    end
  
  end
  
  def ignore_last
    session[:last_search] = ""
    
    respond_to do |format|
      format.js { render :text => "Bye bye :-( ..." }
    end
  end
  
  protected

end
