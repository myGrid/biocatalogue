# BioCatalogue: app/views/registries/index.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <?xml>
xml.instruct! :xml

# <registries>
xml.tag! "registries", 
         xlink_attributes(uri_for_collection("registries", :params => params)), 
         xml_root_attributes,
         :resourceType => "Registries" do
  
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
    xml.pages @registries.total_pages
    
    # <results>
    xml.results @registries.total_entries
    
    # <total>
    xml.total Registry.count
    
  end
  
  # <results>
  xml.results do
    
    # <registry> *
    @registries.each do |registry|
      render :partial => "registries/api/result_item", :locals => { :parent_xml => xml, :registry => registry }
    end
    
  end
  
  # <related>
  xml.related do
    
    params_clone = BioCatalogue::Util.duplicate_params(params)
    
    # Pagination previous next links
    render :partial => "api/pagination/previous_next_links", 
           :locals => { :parent_xml => xml,
                        :resource_type => "Registries",
                        :page => @page,
                        :total_pages => @registries.total_pages,
                        :params_clone => params_clone,
                        :resource_url_lambda => lambda { |params| uri_for_collection("registries", :params => params) } }
    
    # TODO: <sorted> *
    
  end
  
end