# BioCatalogue: app/views/rest_services/api/_ancestors.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <ancestors>
parent_xml.ancestors do
  
  # <service>
  parent_xml.service nil, 
    { :resourceName => display_name(rest_service.service, false), :resourceType => "Service" },
    xlink_attributes(uri_for_object(rest_service.service), :title => xlink_title("The parent Service that this REST Service - #{display_name(rest_service, false)} - belongs to"))
  
end