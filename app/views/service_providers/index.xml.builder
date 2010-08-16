# BioCatalogue: app/views/service_providers/index.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <?xml>
xml.instruct! :xml

# <serviceProviders>
xml.tag! "serviceProviders", 
         xlink_attributes(uri_for_collection("service_providers", :params => params)), 
         xml_root_attributes,
         :resourceType => "ServiceProviders" do
  
  # <parameters>
  xml.parameters do
    
    # Filtering parameters
    render :partial => "api/filtering/parameters", :locals => { :parent_xml => xml, :resource_type => "ServiceProviders" }
    
    # <query>
    xml.query params[:q], :urlKey => "q"
    
    # Sorting parameters
    render :partial => "api/sorting/parameters", :locals => { :parent_xml => xml, :sort_by => @sort_by, :sort_order => @sort_order }
    
    # Pagination parameters
    render :partial => "api/pagination/parameters", :locals => { :parent_xml => xml, :page => @page, :per_page => @per_page }
    
  end
  
  # <statistics>
  xml.statistics do
    
    # <pages>
    xml.pages @service_providers.total_pages
    
    # <results>
    xml.results @service_providers.total_entries
    
    # <total>
    xml.total ServiceProvider.count
    
  end
  
  # <results>
  xml.results do
    
    # <serviceProvider> *
    @service_providers.each do |service_provider|
      render :partial => "service_providers/api/result_item", :locals => { :parent_xml => xml, :service_provider => service_provider }
    end
    
  end
  
  # <related>
  xml.related do
    
    params_clone = BioCatalogue::Util.duplicate_params(params)
    
    # Pagination previous next links
    render :partial => "api/pagination/previous_next_links", 
           :locals => { :parent_xml => xml, 
                        :resource_type => "ServiceProviders",
                        :page => @page,
                        :total_pages => @service_providers.total_pages,
                        :params_clone => params_clone,
                        :resource_url_lambda => lambda { |params| uri_for_collection("service_providers", :params => params) } }

    # <filters>
    xml.filters xlink_attributes(uri_for_collection("service_providers/filters"), 
                                 :title => xlink_title("Filters for the Service Providers index")),
                :resourceType => "Filters"
    
    # <filtersOnCurrentResults>
    xml.filtersOnCurrentResults xlink_attributes(uri_for_collection("service_providers/filters", :params => params_clone.reject{|k,v| k.to_s.downcase == "page" }), 
                                 :title => xlink_title("Filters for the Service Providers index that will be applied on top of the current results set")),
                :resourceType => "Filters"
    
    # TODO: <sorted> *
    
  end
  
end