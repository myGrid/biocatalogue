# BioCatalogue: app/views/registries/api/_related_links.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <related>
parent_xml.related do
    
  # <annotations>
#  parent_xml.annotations xlink_attributes(uri_for_object(registry, :sub_path => "annotations"), :title => xlink_title("All annotations on this Registry - #{display_name(registry, false)}")),
#                         :resourceType => "Registry"
  
  # <annotationsBy>
  parent_xml.annotationsBy xlink_attributes(uri_for_object(registry, :sub_path => "annotations_by"), :title => xlink_title("All annotations by this Registry - #{display_name(registry, false)}")),
                           :resourceType => "Annotations"
  
  # <services>
  parent_xml.services xlink_attributes(uri_for_object(registry, :sub_path => "services"), :title => xlink_title("All services that have been sourced from this Registry - #{display_name(registry, false)}")),
                      :resourceType => "Services"
  
end