# BioCatalogue: app/views/rest_resources/index.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <?xml>
xml.instruct! :xml

# <restResources>
xml.tag! "restResources", 
         xlink_attributes(uri_for_collection("rest_resources", :params => params)), 
         xml_root_attributes,
         :resourceType => "RestResources" do
  
  # <parameters>
  xml.parameters do 

    # Sorting parameters
    render :partial => "api/sorting/parameters", :locals => { :parent_xml => xml, :sort_by => @sort_by, :sort_order => @sort_order }
    
    # Pagination parameters
    render :partial => "api/pagination/parameters", :locals => { :parent_xml => xml, :page => @page, :per_page => @per_page }
    
  end
  
  # <statistics>
  xml.statistics do
    
    # <pages>
    xml.pages @rest_resources.total_pages
    
    # <results>
    xml.results @rest_resources.total_entries
    
    # <total>
    xml.total RestResource.count
    
  end
  
  # <results>
  xml.results do
    
    # <restResource> *
    @rest_resources.each do |res|
      render :partial => "rest_resources/api/inline_item", :locals => { :parent_xml => xml, :rest_resource => res }
    end
    
  end

  # <related>
  xml.related do
    
    params_clone = BioCatalogue::Util.duplicate_params(params)
    
    # Pagination previous next links
    render :partial => "api/pagination/previous_next_links", 
           :locals => { :parent_xml => xml,
                        :resource_type => "RestResources",
                        :page => @page,
                        :total_pages => @rest_resources.total_pages,
                        :params_clone => params_clone,
                        :resource_url_lambda => lambda { |params| uri_for_collection("rest_resources", :params => params) } }
        
  end

end