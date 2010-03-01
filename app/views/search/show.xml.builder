# BioCatalogue: app/views/search/show.xml.builder
#
# Copyright (c) 2008-2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

total_pages = (@results.total.to_f / @per_page.to_f).ceil

# <?xml>
xml.instruct! :xml

# <search>
xml.tag! "search", 
         xlink_attributes(uri_for_collection("search", :params => params)), 
         xml_root_attributes,
         :resourceType => "Search" do
  
  # <parameters>
  xml.parameters do
    
    # <query>
    xml.query @query, :urlKey => "q"
    
    # <scope>
    [ @scope ].flatten.each do |s|
      xml.scope s.titleize, :urlKey => "scope", :urlValue => s
    end
    
    # Pagination parameters
    render :partial => "api/pagination/parameters", :locals => { :parent_xml => xml, :page => @page, :per_page => @per_page }
    
  end
  
  # <statistics>
  xml.statistics do
    
    # <pages>
    xml.pages total_pages
    
    # <results>
    xml.results @results.total
    
    # <scopedResults> *
    @results.result_scopes.each do |result_scope|
      xml.scopedResults @results.count_for(result_scope), :scope => result_scope.titleize
    end
      
  end
  
  # <results>
  xml.results do
    
    paged_item_compound_ids = @results.paged_all_item_ids(@page, @per_page)
    items = search_item_compound_ids_to_objects(paged_item_compound_ids)
    
    if @page < total_pages && items.length != @per_page
      BioCatalogue::Util.yell "Incorrect number of items per page! paged_item_compound_ids = #{paged_item_compound_ids.inspect}"
    end
    
    items.each do |item|
      render :partial => "#{item.class.name.underscore.pluralize}/api/result_item", :locals => { :parent_xml => xml, item.class.name.underscore.to_sym => item }
    end
    
  end
  
  # <related>
  xml.related do
    
    params_clone = BioCatalogue::Util.duplicate_params(params)
    
    # Pagination previous next links
    render :partial => "api/pagination/previous_next_links", 
           :locals => { :parent_xml => xml,
                        :resource_type => "Search",
                        :page => @page,
                        :total_pages => total_pages,
                        :params_clone => params_clone,
                        :resource_url_lambda => lambda { |params| uri_for_collection("search", :params => params) } }
    
    # <searches>
    xml.searches do 
      
      # <scoped> *
      BioCatalogue::Search::VALID_SEARCH_SCOPES_INCL_ALL.each do |result_scope|
        unless result_scope == @scope
          xml.scoped "", 
                     { :scope => result_scope.titleize, :resourceType => "Search" },
                     xlink_attributes(uri_for_collection("search", :params => params_clone.merge(:scope => result_scope).reject{|k,v| k.to_s.downcase == "page" }), 
                                      :title => xlink_title("Search results for #{result_scope.titleize}"))
        end
      end      
      
    end
    
  end
  
end