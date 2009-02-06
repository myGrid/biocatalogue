# BioCatalogue: app/controllers/search_controller.rb
#
# Copyright (c) 2008, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

class SearchController < ApplicationController
  
  def show
    
    # First check that search is available
    unless search_available?
      flash[:error] = 'Search is unavailable at this time'
      redirect_to root_url
      return
    end
    
    @query = params[:query] || ''
    @query = @query.downcase.strip
    #@query = @query + "~" unless @query.ends_with?('~')
    
    # Check query is present
    if @query.blank?
      error('No search query provided')
      return
    end
    
    # Check if the query is '*' in which case give the user an appropriate message.
    if @query == '*'
      error("It looks like you were trying to search for everything in BioCatalogue! If you would like to browse all services then <a href='#{services_path}'>click here</a>.")
      return
    end
    
    # Check if the query was for a URL, in which case wrap it in quotation marks in order to get through the solr query parser.
    if @query.starts_with?("http://") or 
       @query.starts_with?("https://")
      @query = '"' + @query
      @query = @query + '"'
    end
    
    @type = params[:type]
    
    if @type.blank?
      @type = "all"
    else
      @type = @type.strip.downcase.pluralize
    end
    
    any_types_synonyms = [ "all", "any" ]
    
    # Check that a valid type has been provided
    unless any_types_synonyms.include?(@type) || VALID_SEARCH_TYPES.include?(@type)
      error("'#{@type}' is an invalid search type")
      return false
    end
    
    # Log this search, if allowed.
    if USE_EVENT_LOG
      ActivityLog.create(:action => "search", :culprit => current_user, :data => { :query => @query, :type =>  @type })
    end
    
    # Now either peform an 'all' search or redirect to the appropriate type's search action
    if any_types_synonyms.include?(@type)
      @count = 0
      @results = { }
      
      begin
        @count, @results = get_all_results(@query)
      rescue Exception => ex
        flash.now[:error] = "Search failed. Possible bad search term."
        logger.error("ERROR: search failed for query: '#{@query}'. Exception:")
        logger.error(ex)
      end
      
      respond_to do |format|
        format.html # show.html.erb
        format.xml { set_no_layout } # show.xml.builder
      end
    else
      redirect_to :controller => @type, :action => "search", :query => params[:query]
    end
  end
  
protected

  def search_available?
    return ENABLE_SEARCH
  end
  
  def get_all_results(query)
    # First go through each model and fetch all search results.
    
    limit = 5000
    all_results = [ ]
    
    # ===========
    # NOTE: do not use Service.find_by_solr as this will break due to a bad bug in acts_as_solr. 
    # This bug essentially treates any model with the word "Service" in it as a Service object
    # and therefore parses the results from solr incorrectly!    
    # ===========
    
    # As new models are indexed (and therefore need to be searched on) add them here.
    models = [ Service, ServiceVersion, ServiceDeployment,
               SoapService, SoapOperation, SoapInput, SoapOutput,
               User, ServiceProvider,
               Annotation ]
    
    
    all_results = Service.multi_solr_search(query, :limit => limit, :models => models).results
    
    # Then collect together the appropriate results.
    
    total_count, grouped_results = BioCatalogue::Util.group_model_objects(all_results, VALID_SEARCH_TYPES, true)
    
    return [ total_count, grouped_results ]

  end

  def error(msg)
    flash[:error] = msg
    
    respond_to do |format|
      format.html { redirect_to (session[:original_uri].nil? ? home_url : :back) }
      format.xml { render :xml => "<errors><error>#{msg}</error></errors>" }
    end
  end

end
