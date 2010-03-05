# BioCatalogue: app/views/api/filtering/_filters.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <filters>

parent_xml.tag! "filters", 
                xlink_attributes(uri_for_collection("#{resource_type}/filters", :params => params)), 
                xml_root_attributes, 
                :for => resource_type,
                :resourceType => "Filters" do
  
  BioCatalogue::Filtering::FILTER_KEYS[resource_type.underscore.to_sym].each do |filter_key|
    
    # <filterType>
    parent_xml.filterType :name => BioCatalogue::Filtering.filter_type_to_display_name(filter_key), :urlKey => filter_key.to_s do
      
      # <filter> *
      filters = eval("BioCatalogue::Filtering::#{resource_type.camelize}.get_filters_for_filter_type(filter_key, @limit || 100)")
      xml_for_filters(parent_xml, filters, filter_key, resource_type)
      
    end
    
  end
  
end