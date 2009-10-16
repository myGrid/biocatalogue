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
  
  before_filter :set_listing_type, :only => [ :show ]
  
  def show
    
    if @query.blank?

      respond_to do |format|
        format.html # show.html.erb
        format.xml  # show.xml.builder
      end
      
    else
      begin
        @results = BioCatalogue::Search.search(@query, @scope)
        raise "nil @results object returned" if @results.nil?
      rescue Exception => ex
        flash.now[:error] = "Sorry, search didn't work this time. Try with different keyword(s). Please <a href='/contact'>report this</a> if it continues for other searches."
        logger.error("Search failed for query: '#{@query}'. Exception:")
        logger.error(ex.message)
        logger.error(ex.backtrace.join("\n"))
      end
      
      respond_to do |format|
        format.html # show.html.erb
        format.xml  # show.xml.builder
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

      # Query is fine
      @query = query
      
      # Now, the scope...
      
      scope = params[:scope]
      
      # Normalise scope
      if scope.blank?
        scope = BioCatalogue::Search::ALL_SCOPE_SYNONYMS[0]
      else
        scope = scope.strip.downcase
        scope = BioCatalogue::Search::ALL_SCOPE_SYNONYMS[0] if BioCatalogue::Search::ALL_SCOPE_SYNONYMS[1..-1].include?(scope)
        
        # Reset params[:scope] in case it is accessed again
        params[:scope] = scope 
      end

      # Check that a valid scope has been provided
      unless BioCatalogue::Search::VALID_SEARCH_SCOPES_INCL_ALL.include?(scope)
        error_to_home("'#{scope}' is an invalid search scope")
        return false
      end

      # Scope is fine
      @scope = scope

      @results = nil

    end
  end

  def remember_search
    unless is_non_html_request?
      session[:last_search] = request.url if defined?(@results) and !@results.nil? and @results.total > 0
    end
  end
  
  def set_listing_type
    @allowed_listing_types ||= [ "simple", "detailed" ]
    
    default_type = :simple
    session_key = "search_#{action_name}_listing_type"
    
    if !params[:listing].blank? and @allowed_listing_types.include?(params[:listing].downcase)
      @listing_type = params[:listing].downcase.to_sym
      session[session_key] = params[:listing].downcase
    elsif !session[session_key].blank?
      @listing_type = session[session_key].to_sym
    else
      @listing_type = default_type
      session[session_key] = default_type.to_s 
    end
  end

end
