class SearchController < ApplicationController
  
  def show
    
    # First check that search is available
    unless search_available?
      flash[:error] = 'Search is unavailable at this time'
      redirect_to root_url
      return
    end
    
    @query = params[:query] || ''
    @query.strip!
    
    # Check query is present
    if @query.blank?
      flash[:error] = 'No search query provided'
      redirect_to :back
      return
    end
    
    @type = params[:type]
    
    if @type.blank?
      @type = "all"
    else
      @type = @type.strip!.downcase!.pluralize
    end
    
    any_types_synonyms = [ "all", "any" ]
    
    # Check that a valid type has been provided
    unless any_types_synonyms.include?(@type) || VALID_SEARCH_TYPES.include?(@type)
      error(@type)
      return false
    end
    
    # Now either peform an all search or redirect to the appropriate type's search action
    if any_types_synonyms.include?(@type)
      models = VALID_SEARCH_TYPES.map{|t| t.singularize.capitalize.constantize}
      all_search_results = Service.multi_solr_search(@query, :limit => 100, :models => models).results
      
      @count = all_search_results.length
      @results = { }
  
      models.each do |m|
        @results[m.to_s.titleize.pluralize] = all_search_results.select{|r| r.instance_of?(m)}
      end
      
      respond_to do |format|
        format.html # show.html.erb
      end
      
    else
      redirect_to :controller => @type, :action => "search", :query => params[:query]
    end
  end
  
protected

  def search_available?
    return ENABLE_SEARCH
  end

  def error(type)
    flash[:error] = "'#{type}' is an invalid search type"
    
    respond_to do |format|
      format.html { redirect_to :back }
    end
  end

end
