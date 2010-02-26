# BioCatalogue: app/controllers/search_controller.rb
#
# Copyright (c) 2008, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

class SearchController < ApplicationController
  
  before_filter :disable_action_for_api, :except => [ :show, :by_data ]
  
  skip_before_filter :verify_authenticity_token, :only => [ :auto_complete, :by_data ]
  
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
  
  def by_data
    @results = nil
    @query = nil
    @search_type = "input"
    @limit=20
    
    if params[:search_by_data].blank?
      error_to_home("Something went wrong. Please contact us if this carries on.")
      return
    end
    
    if request.post?
      #puts params.inspect
      if !params[:search_by_data][:search_type].nil? && params[:search_by_data][:search_type].downcase == "output"
        @search_type = "output"
      end
      if params[:search_by_data][:limit]!=nil and params[:search_by_data][:limit].match(/^\d+$/)
        begin
          limit=Integer(params[:search_by_data][:limit])
          if limit>0
            @limit=limit
          end
        rescue ArgumentError
        end      
      end
      #puts params[:search_by_data][:data]
      unless params[:search_by_data][:data].blank?
        if is_api_request? 
          @query=cgi.unescape(params[:search_by_data][:data])
        else
          @query=params[:search_by_data][:data]
        end

        if @search_type == "input"
          @results=BioCatalogue::SearchByData.get_matching_input_ports_for_data(@query,@limit)
        elsif @search_type == "output"
          @results=BioCatalogue::SearchByData.get_matching_output_ports_for_data(@query,@limit)
        end
      end
    
    end
    
    respond_to do |format|
      format.html # by_data.html.erb
      format.xml  # by_data.xml.builder
    end
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
      
      # Now, the scope(s)...
      
      scope = params[:scope]
      
      # Normalise scope
      if scope.blank?
        scope = BioCatalogue::Search::ALL_SCOPE_SYNONYMS[0]
      else
        
        # Can be a single scope or a list of scopes...
        
        if scope =~ /,/
          scope = scope.split(',').compact.map{|s| s.strip.downcase}.reject{|s| !BioCatalogue::Search::VALID_SEARCH_SCOPES_INCL_ALL.include?(s)}
        else
          scope = scope.strip.downcase
          scope = BioCatalogue::Search::ALL_SCOPE_SYNONYMS[0] if BioCatalogue::Search::ALL_SCOPE_SYNONYMS.include?(scope)
          
          # Check that a valid scope has been provided
          unless BioCatalogue::Search::VALID_SEARCH_SCOPES_INCL_ALL.include?(scope)
            error_to_home("'#{scope}' is an invalid search scope")
            return false
          end
        end
        
      end

      # Scope(s) is fine
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
