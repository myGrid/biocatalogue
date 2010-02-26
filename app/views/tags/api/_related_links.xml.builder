# BioCatalogue: app/views/tags/api/_related_links.xml.builder
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <related>
parent_xml.related do
  
  # <services>
  parent_xml.services xlink_attributes(generate_include_filter_url(:tag, tag_name, "services"), :title => xlink_title("List of filtered services for tag '#{tag_name}'")),
                      :resourceType => "Services"
  
end