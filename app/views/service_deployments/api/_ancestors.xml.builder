# BioCatalogue: app/views/service_deployments/api/_ancestors.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <ancestors>
parent_xml.ancestors do
  
  # <service>
  parent_xml.service nil, 
    { :resourceName => display_name(service_deployment.service, false), :resourceType => "ServiceDeployment" },
    xlink_attributes(uri_for_object(service_deployment.service), :title => xlink_title("The parent Service that this Service Deployment belongs to"))
  
end