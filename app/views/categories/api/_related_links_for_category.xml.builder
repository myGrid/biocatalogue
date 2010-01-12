# BioCatalogue: app/views/categories/api/_related_links_for_category.xml.builder
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <related>
parent_xml.related do
    
  # <filteredServices>
  parent_xml.filteredServices xlink_attributes(generate_include_filter_url(:cat, category.id), :title => xlink_title("List of filtered services for category '#{display_name(category)}'"))
  
end