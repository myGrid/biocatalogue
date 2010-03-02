# BioCatalogue: app/views/search/by_data.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <?xml>
xml.instruct! :xml

# <searchByData>
xml.tag! "searchByData", 
         xlink_attributes(uri_for_collection("search/by_data")), 
         xml_root_attributes,
         :resourceType => "SearchByData" do
  
  # <parameters>
  xml.parameters do
    
    # <query>
    xml.data @query
    
    # <searchType>
    xml.searchType @search_type
    
    # <limit>
    xml.limit @limit
    
  end
  
  # <statistics>
  xml.statistics do
    
    # <pages>
    xml.pages 1
    
    # <results>
    if not @results
      xml.results 0
    else
      xml.results @results.all_items.length       
    end
    
  end
  
  # <results>
  xml.results do
    
    if @results
      
      # <resultItem> *
      
      @results.all_items.each do |result|
        
        xml.resultItem do
          
          # <service>
          xml.service xlink_attributes(uri_for_object(result.service), :title => xlink_title(result.service)),
            :resourceType => "Service",
            :resourceName => display_name(result.service, false)
          
          # <soapOperation>
          xml.soapOperation xlink_attributes(uri_for_object(result.operation), :title => xlink_title(result.operation)),
            :resourceType => "SoapOperation",
            :resourceName => display_name(result.operation, false)
          
          # <port>
          xml.port xlink_attributes(uri_for_object(result.port), :title => xlink_title(result.port)),
            :resourceType => result.port.class.name,
            :resourceName => display_name(result.port, false)
          
          # <annotation>
          xml.annotation xlink_attributes(uri_for_object(result.annotation), :title => xlink_title(result.annotation)),
            :resourceType => "Annotation"
          
        end
        
      end
      
    end
    
  end
  
  # <related>
  xml.related nil
  
end