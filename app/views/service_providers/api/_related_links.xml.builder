# BioCatalogue: app/views/service_providers/api/_related_links.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <related>
parent_xml.related do
    
  # <annotations>
  parent_xml.annotations xlink_attributes(uri_for_object(service_provider, :sub_path => "annotations"), :title => xlink_title("All annotations on this Service Provider - #{display_name(service_provider, false)}")),
                         :resourceType => "Annotations"
  
  # <annotationsBy>
  parent_xml.annotationsBy xlink_attributes(uri_for_object(service_provider, :sub_path => "annotations_by"), :title => xlink_title("All annotations by this Service Provider - #{display_name(service_provider, false)}")),
                           :resourceType => "Annotations"
  
  # <services>
  parent_xml.services xlink_attributes(uri_for_object(service_provider, :sub_path => "services"), :title => xlink_title("All services that this Service Provider - #{display_name(service_provider, false)} - provides")),
                      :resourceType => "Services"
  
end