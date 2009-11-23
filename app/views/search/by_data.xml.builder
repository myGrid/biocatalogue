# <?xml>
xml.instruct! :xml

# <search>
xml.tag! "searchByData", 
         xlink_attributes(uri_for_collection("by_data", :params => params)), 
         xml_root_attributes do
  xml.parameters do
    xml.data @query
    xml.search_type @search_type
    xml.limit @limit
  end
  xml.statistics do
    if not @results
      xml.itemCounts 0
    else
      xml.itemCounts @results.all_items.length       
    end
  end
  xml.results do
    if @results
      @results.all_items.each do |result|
        xml.resultItem do
          xml.service xlink_attributes(uri_for_object(result.service)) do
            xml.serviceName result.service.name
          end
          xml.soapOperation xlink_attributes(uri_for_object(result.operation)) do
            xml.operationName result.operation.name
          end
          xml.port xlink_attributes(uri_for_object(result.port)) do
            xml.portName result.port.name
          end
          xml.annotation xlink_attributes(uri_for_object(result.annotation)) do
            xml.annotationValue result.annotation.value
          end
        end
      end
    end
  end
  xml.related do
  end
end