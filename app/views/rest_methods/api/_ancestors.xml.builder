# BioCatalogue: app/views/rest_methods/api/_ancestors.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <ancestors>
parent_xml.ancestors do
  
  # <service>
  service = rest_method.associated_service
  parent_xml.service nil, 
    { :resourceName => display_name(service, false), :resourceType => "Service" },
    xlink_attributes(uri_for_object(service), :title => xlink_title("The parent Service that this REST Method - #{display_name(rest_method, false)} - belongs to"))
  
  # <restService>
  rest_service = rest_method.rest_resource.rest_service
  parent_xml.restService nil, 
    { :resourceName => display_name(rest_service, false), :resourceType => "RestService" },
    xlink_attributes(uri_for_object(rest_service), :title => xlink_title("The parent REST Service that this REST Method - #{display_name(rest_method, false)} - belongs to"))

  # <restResource>
  parent_xml.restResource nil, 
    { :resourceName => display_name(rest_method.rest_resource, false), :resourceType => "RestResource" },
    xlink_attributes(uri_for_object(rest_method.rest_resource), :title => xlink_title("The parent REST Resource that this REST Method - #{display_name(rest_method, false)} - belongs to"))
    
end