# BioCatalogue: app/views/services/index.xml.builder
#
# Copyright (c) 2009-2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <?xml>
xml.instruct! :xml

# <services>
xml.tag! "services", 
         xlink_attributes(uri_for_collection("services", :params => params)), 
         xml_root_attributes,
         :resourceType => "Services" do
  
  # <parameters>
  xml.parameters do
    
    # Filtering parameters
    render :partial => "api/filtering/parameters", :locals => { :parent_xml => xml }
    
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
    xml.pages @services.total_pages
    
    # <results>
    xml.results @services.total_entries
    
    # <total>
    xml.total Service.count
    
  end
  
  # <results>
  xml.results do
    
    # <service> *
    @services.each do |service|
      render :partial => "services/api/result_item", :locals => { :parent_xml => xml, :service => service }
    end
    
  end
  
  # <related>
  xml.related do
    
    params_clone = BioCatalogue::Util.duplicate_params(params)
    
    # Pagination previous next links
    render :partial => "api/pagination/previous_next_links", 
           :locals => { :parent_xml => xml, 
                        :resource_type => "Services",
                        :page => @page,
                        :total_pages => @services.total_pages,
                        :params_clone => params_clone,
                        :resource_url_lambda => lambda { |params| uri_for_collection("services", :params => params) } }
    
    params_clone.reject!{|k,v| k.to_s.downcase == "page" }
    
    # <filters>
    xml.filters xlink_attributes(uri_for_collection("services/filters", :params => params_clone), 
                                 :title => xlink_title("Filters for the services index")),
                :resourceType => "Filters"
    
    # TODO: <sorted> *
    
    # <withSummaries>
    params_clone['include'] = "summary"
    xml.withSummaries xlink_attributes(uri_for_collection("services", :params => params_clone), 
                                 :title => xlink_title("The services index but with the <summary> element included for each service. This always you to get lots of metadata about the services returned without having to make additional calls.")),
                :resourceType => "Services"
    
  end
  
end