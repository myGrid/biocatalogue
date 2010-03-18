# BioCatalogue: app/views/agents/index.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <?xml>
xml.instruct! :xml

# <agents>
xml.tag! "agents", 
         xlink_attributes(uri_for_collection("agents", :params => params)), 
         xml_root_attributes,
         :resourceType => "Agents" do
  
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
    xml.pages @agents.total_pages
    
    # <results>
    xml.results @agents.total_entries
    
    # <total>
    xml.total Agent.count
    
  end
  
  # <results>
  xml.results do
    
    # <agent> *
    @agents.each do |agent|
      render :partial => "agents/api/result_item", :locals => { :parent_xml => xml, :agent => agent }
    end
    
  end
  
  # <related>
  xml.related do
    
    params_clone = BioCatalogue::Util.duplicate_params(params)
    
    # Pagination previous next links
    render :partial => "api/pagination/previous_next_links", 
           :locals => { :parent_xml => xml,
                        :resource_type => "Agents",
                        :page => @page,
                        :total_pages => @agents.total_pages,
                        :params_clone => params_clone,
                        :resource_url_lambda => lambda { |params| uri_for_collection("agents", :params => params) } }
    
    # TODO: <sorted> *
    
  end
  
end