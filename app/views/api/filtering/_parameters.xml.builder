# BioCatalogue: app/views/api/filtering/_parameters.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <filters>
parent_xml.filters do
  @current_filters.each do |filter_key, filter_ids|
    # <filterType>
    parent_xml.filterType :name => BioCatalogue::Filtering.filter_type_to_display_name(filter_key), :urlKey => filter_key.to_s do
      filter_ids.each do |f_id|
        # <filter>
        parent_xml.filter display_name_for_filter(filter_key, f_id), :urlValue => f_id
      end
    end
  end
end
