# BioCatalogue: app/controllers/search_controller.rb
#
# Copyright (c) 2008, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

class SearchController < ApplicationController
  
  skip_before_filter :verify_authenticity_token, :only => [ :auto_complete ]
  
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
      begin
        # Either peform an 'all' search or redirect to the appropriate type's search action
        if BioCatalogue::Search::ALL_TYPES_SYNONYMS.include?(@type)
          @results = BioCatalogue::Search.search_all(@query)
        else
          @results = BioCatalogue::Search.search(@query, @type)
        end
        raise "nil @results object returned" if @results.nil?
      rescue Exception => ex
        flash.now[:error] = "Sorry, search didn't work this time. Try with different keyword(s). Please <a href='/contact'>report this</a> if it continues for other searches."
        logger.error("Search failed for query: '#{@query}'. Search has still been logged in the activity log. Exception:")
        logger.error(ex.message)
        logger.error(ex.backtrace.join("\n"))
      end
      
      respond_to do |format|
        format.html # show.html.erb
        format.xml { render :layout => false } # show.xml.builder
      end
    
    end
  
  end
  
  def ignore_last
    session[:last_search] = ""
    
    respond_to do |format|
      format.js { render :text => "Bye bye :-( ..." }
    end
  end
  
  def auto_complete
    @query_fragment = '';
    @query_fragment = params[:q] unless params[:q].blank?
    
    @queries = BioCatalogue::Search.get_query_suggestions(@query_fragment, 50)
                     
    render :inline => "<%= auto_complete_result @queries, 'name', @query_fragment %>", :layout => false
  end
  
  
  protected
  
  
  def validate_and_setup_search
    # First check that search is on
    unless BioCatalogue::Search.on?
      error_to_home('Search is unavailable at this time')
      return false
    end

    query = (params[:q] || '').strip

    # Check query is present
    unless query.blank?

      # Check if the query is '*' in which case give the user an appropriate message.
      if query == '*'
        error_to_home("It looks like you were trying to search for everything in the BioCatalogue! If you would like to browse all services then <a href='#{services_path}'>click here</a>.")
        return false
      end
      
      if query.match(/^[*]/)
        error_to_home("Unfortunately you can't start your queries with '*'. Please try again without the '*'.")
        return false
      end

      # Query is fine...
      @query = query

      type = params[:t]

      if type.blank?
        type = "all"
      else
        type = type.strip.downcase.pluralize
      end

      all_valid_types = BioCatalogue::Search::VALID_SEARCH_TYPES + BioCatalogue::Search::ALL_TYPES_SYNONYMS

      # Check that a valid type has been provided
      unless all_valid_types.include?(type)
        error_to_home("'#{type}' is an invalid search type")
        return false
      end

      # Type is fine...
      @type = type

      @results = nil

    end
  end

  def remember_search
    session[:last_search] = request.url if defined?(@results) and !@results.nil? and @results.total > 0
  end

end
