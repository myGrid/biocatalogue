# BioCatalogue: app/views/categories/api/_related_links.xml.builder
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <related>
parent_xml.related do
    
  # <services>
  parent_xml.services xlink_attributes(uri_for_object(category, :sub_path => "services"), :title => xlink_title("The services that have the category '#{display_name(category, false)}'")),
                      :resourceType => "Services"
  
end