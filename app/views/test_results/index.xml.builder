# BioCatalogue: app/views/test_results/index.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <?xml>
xml.instruct! :xml

# <testResults>
xml.tag! "testResults", 
         xlink_attributes(uri_for_collection("test_results", :params => params)), 
         xml_root_attributes,
         :resourceType => "TestResults" do
  
  # <parameters>
  xml.parameters do
    
    # Sorting parameters
    render :partial => "api/sorting/parameters", :locals => { :parent_xml => xml, :sort_by => @sort_by, :sort_order => @sort_order }
    
    # Pagination parameters
    render :partial => "api/pagination/parameters", :locals => { :parent_xml => xml, :page => @page, :per_page => @per_page }
    
    # <serviceTest>
    if @service_test
      xml.serviceTest nil, 
        { :resourceName => display_name(@service_test, false), :resourceType => "ServiceTest" },
        xlink_attributes(uri_for_object(@service_test), :title => xlink_title("The specified Service Test that these Test Results are for"))
    end
  end
  
  # <statistics>
  xml.statistics do
    
    # <pages>
    xml.pages @test_results.total_pages
    
    # <results>
    xml.results @test_results.total_entries
    
    # <total>
    xml.total TestResult.count
    
  end
  
  # <results>
  xml.results do
    
    # <test_result> *
    @test_results.each do |test_result|
      render :partial => "test_results/api/result_item", :locals => { :parent_xml => xml, :test_result => test_result }
    end
    
  end
  
  # <related>
  xml.related do
    
    params_clone = BioCatalogue::Util.duplicate_params(params)
    
    # Pagination previous next links
    render :partial => "api/pagination/previous_next_links", 
           :locals => { :parent_xml => xml, 
                        :resource_type => "TestResults",
                        :page => @page,
                        :total_pages => @test_results.total_pages,
                        :params_clone => params_clone,
                        :resource_url_lambda => lambda { |params| uri_for_collection("test_results", :params => params) } }
    
    # TODO: <sorted> *
    
  end
  
end