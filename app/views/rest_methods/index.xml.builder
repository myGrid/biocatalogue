# BioCatalogue: app/views/rest_methods/index.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <?xml>
xml.instruct! :xml

# <restMethods>
xml.tag! "restMethods", 
         xlink_attributes(uri_for_collection("rest_methods", :params => params)), 
         xml_root_attributes,
         :resourceType => "RestMethods" do
  
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
    xml.pages @rest_methods.total_pages
    
    # <results>
    xml.results @rest_methods.total_entries
    
    # <total>
    xml.total RestMethod.count
    
  end
  
  # <results>
  xml.results do
    
    # <restMethod> *
    @rest_methods.each do |meth|
      render :partial => "rest_methods/api/inline_item", :locals => { :parent_xml => xml, :rest_method => meth }
    end
    
  end

  # <related>
  xml.related do
    
    params_clone = BioCatalogue::Util.duplicate_params(params)
    
    # Pagination previous next links
    render :partial => "api/pagination/previous_next_links", 
           :locals => { :parent_xml => xml,
                        :resource_type => "RestMethods",
                        :page => @page,
                        :total_pages => @rest_methods.total_pages,
                        :params_clone => params_clone,
                        :resource_url_lambda => lambda { |params| uri_for_collection("rest_methods", :params => params) } }
        
  end

end