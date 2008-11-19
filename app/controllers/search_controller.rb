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
    @query.strip!
    
    # Check query is present
    if @query.blank?
      flash[:error] = 'No search query provided'
      redirect_to :back
      return
    end
    
    # Check if the query is '*' in which case give the user an appropriate message.
    if @query == '*'
      flash[:error] = "It looks like you were trying to search for everything in BioCatalogue! If you would like to browse all services then <a href='#{services_path}'>click here</a>."
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
    
    # Log this search, if allowed.
    if USE_EVENT_LOG
      ActivityLog.create(:action => "search", :culprit => current_user, :data => { :query => @query, :type =>  @type })
    end
    
    # Now either peform an all search or redirect to the appropriate type's search action
    if any_types_synonyms.include?(@type)
      models = VALID_SEARCH_TYPES.map{|t| t.classify.constantize}
      
      # The following line seems to be returning the wrong model types.
      #all_search_results = User.multi_solr_search(@query, :limit => 100, :models => models).results
      
      @count = 0
      @results = { }
  
      models.each do |m|
        m_name = m.to_s.titleize.pluralize
        @results[m_name] = [ ]
        res = m.multi_solr_search(@query, :models => [ m ]).results.uniq
        res.each do |r|
          if r.is_a?(m)
            @count = @count + 1
            @results[m_name] << r
          end
        end
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
