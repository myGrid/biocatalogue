# BioCatalogue: app/views/tags/index.xml.builder
#
# Copyright (c) 2009-2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <?xml>
xml.instruct! :xml

# <services>
xml.tag! "tags", 
         xlink_attributes(uri_for_collection("tags", :params => params)), 
         xml_root_attributes,
         :resourceType => "Tags" do
  
  # <parameters>
  xml.parameters do
    
    # <sort>
    xml.tag! "sort", @sort.to_s.titleize, :urlKey => "sort", :urlValue => @sort.to_s
    
    # Pagination parameters
    render :partial => "api/pagination/parameters", :locals => { :parent_xml => xml, :page => @page, :per_page => @per_page }
    
    # <limit>
    xml.limit @limit, (@limit.nil? ? { "xsi:nil" => "true" } : { })
    
  end
  
  # <statistics>
  xml.statistics do
    
    # <pages>
    xml.pages @tags.total_pages
    
    # <results>
    xml.results @tags.total_entries
    
    # <total>
    xml.total @total_tags_count
    
  end
  
  # <results>
  xml.results do
    
    # <tag> *
    @tags.each do |t|
      render :partial => "tags/api/result_item", :locals => { :parent_xml => xml, :tag_name => t['name'], :tag_display_name => BioCatalogue::Tags.split_ontology_term_uri(t['name'])[1], :total_items_count => t['count'] }
    end
    
  end
  
  # <related>
  xml.related do
    
    # Pagination previous next links
    render :partial => "api/pagination/previous_next_links", 
           :locals => { :parent_xml => xml,
                        :resource_type => "Tags",
                        :page => @page,
                        :total_pages => @tags.total_pages,
                        :resource_url_lambda => lambda { |params| uri_for_collection("tags", :params => params) } }
    
  end
  
end