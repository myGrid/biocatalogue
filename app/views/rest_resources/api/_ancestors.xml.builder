# BioCatalogue: app/views/rest_resources/api/_ancestors.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <ancestors>
parent_xml.ancestors do
  
  # <service>
  service = Service.find(rest_resource.associated_service_id)
  parent_xml.service nil, 
    { :resourceName => display_name(service, false), :resourceType => "Service" },
    xlink_attributes(uri_for_object(service), :title => xlink_title("The parent Service that this REST endpoint - #{display_name(rest_resource, false)} - belongs to"))
  
  # <restService>
  parent_xml.restService nil, 
    { :resourceName => display_name(rest_resource.rest_service, false), :resourceType => "RestService" },
    xlink_attributes(uri_for_object(rest_resource.rest_service), :title => xlink_title("The parent REST Service that this REST endpoint - #{display_name(rest_resource, false)} - belongs to"))
    
end