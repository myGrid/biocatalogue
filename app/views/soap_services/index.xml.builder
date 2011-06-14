# BioCatalogue: app/views/soap_services/index.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <?xml>
xml.instruct! :xml

# <soapServices>
xml.tag! "soapServices", 
         xlink_attributes(uri_for_collection("soap_services", :params => params)), 
         xml_root_attributes,
         :resourceType => "SoapServices" do
  
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
    xml.pages @soap_services.total_pages
    
    # <results>
    xml.results @soap_services.total_entries
    
    # <total>
    xml.total SoapService.count
    
  end
  
  # <results>
  xml.results do
    
    # <restMethod> *
    @soap_services.each do |s|
      render :partial => "soap_services/api/result_item", :locals => { :parent_xml => xml, :soap_service => s }
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
                        :total_pages => @soap_services.total_pages,
                        :params_clone => params_clone,
                        :resource_url_lambda => lambda { |params| uri_for_collection("soap_services", :params => params) } }
        
  end

end