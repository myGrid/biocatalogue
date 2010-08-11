# BioCatalogue: app/views/rest_services/api/_related_links.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <related>
parent_xml.related do
  
  # <deployments>
  parent_xml.deployments xlink_attributes(uri_for_object(rest_service, :sub_path => "deployments"), :title => xlink_title("The service deployments that host this REST Service - #{display_name(rest_service, false)}")),
                         :resourceType => "RestService"

  # <resources>
  parent_xml.resources xlink_attributes(uri_for_object(rest_service, :sub_path => "resources"), :title => xlink_title("The REST Resources provided by this REST Service - #{display_name(rest_service, false)}")),
                         :resourceType => "RestService"
    
  # <annotations>
  parent_xml.annotations xlink_attributes(uri_for_object(rest_service, :sub_path => "annotations"), :title => xlink_title("All annotations on this REST Service - #{display_name(rest_service, false)}")),
                         :resourceType => "Annotations"
  
end