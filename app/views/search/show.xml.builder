# BioCatalogue: app/views/search/show.xml.builder
#
# Copyright (c) 2008-2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

total_pages = (@results.total.to_f / PAGE_ITEMS_SIZE.to_f).ceil

# <?xml>
xml.instruct! :xml

# <search>
xml.tag! "search", 
         xlink_attributes(uri_for_collection("search", :params => params)), 
         xml_root_attributes do
  
  # <parameters>
  xml.parameters do
    
    # <query>
    xml.query @query, :urlKey => "q"
    
    # <scope>
    xml.scope @scope.titleize, :urlKey => "scope", :urlValue => @scope
    
    # <page>
    xml.page  @page, :urlKey => "page"
    
  end
  
  # <statistics>
  xml.statistics do
    
    # <totalPages>
    xml.totalPages total_pages
    
    # <itemCounts>
    xml.itemCounts do 
      
      # <total>
      xml.total @results.total
      
      # <scoped> *
      @results.result_scopes.each do |result_scope|
        xml.scoped @results.count_for(result_scope), :scope => result_scope.titleize
      end
      
    end
    
  end
  
  # <results>
  xml.results do
    
    paged_item_compound_ids = @results.paged_all_item_ids(@page, PAGE_ITEMS_SIZE)
    items = search_item_compound_ids_to_objects(paged_item_compound_ids)
    
    items.each do |item|
      xml.tag! item.class.name.camelize(:lower), xlink_attributes(uri_for_object(item), :title => xlink_title(item)) do 
        if item.is_a? Service
          render :partial => "services/api/result_item", :locals => { :parent_xml => xml, :service => item }
        else
          xml.name display_name(item)
        end
        
      end
    end
    
  end
  
  # <related>
  xml.related do
    
    params_clone = BioCatalogue::Util.duplicate_params(params)
    
    # <previous>
    unless @page == 1
      xml.previous previous_link_xml_attributes(uri_for_collection("search", :params => params_clone.merge(:page => (@page - 1))))
    end
    
    # <next>
    unless total_pages == 0 or total_pages == @page 
      xml.next next_link_xml_attributes(uri_for_collection("search", :params => params_clone.merge(:page => (@page + 1))))
    end
    
    # <searches>
    xml.searches do 
      
      # <scoped> *
      BioCatalogue::Search::VALID_SEARCH_SCOPES_INCL_ALL.each do |result_scope|
        unless result_scope == @scope
          xml.scoped "", 
                     { :scope => result_scope.titleize },
                     xlink_attributes(uri_for_collection("search", :params => params_clone.merge(:scope => result_scope).reject{|k,v| k.to_s.downcase == "page" }), 
                                      :title => xlink_title("Search results for #{result_scope.titleize}"))
        end
      end      
      
    end
    
  end
  
end