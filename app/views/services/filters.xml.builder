# BioCatalogue: app/views/services/filters.xml.builder
#
# Copyright (c) 2008-2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <?xml>
xml.instruct! :xml

# <filters>
xml.tag! "filters", 
         xlink_attributes(uri_for_collection("services/filters", :params => params)), 
         xml_root_attributes do
  
  BioCatalogue::Filtering::FILTER_KEYS.each do |filter_key|
    
    # <filterType>
    xml.filterType :name => BioCatalogue::Filtering.filter_type_to_display_name(filter_key), :urlKey => filter_key.to_s do
      
      # <filter> *
      
      filters = BioCatalogue::Filtering.get_filters_for_filter_type(filter_key, 100)
      
      xml_for_filters(xml, filters, filter_key)
      
    end
    
  end
  
end