# BioCatalogue: app/views/soap_services/api/_related_links.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <related>
parent_xml.related do
  
  # <deployments>
  parent_xml.deployments xlink_attributes(uri_for_object(soap_service, :sub_path => "deployments"), :title => xlink_title("The service deployments that host this SOAP Service")),
                         :resourceType => "SoapService"
  
  # <operations>
  parent_xml.operations xlink_attributes(uri_for_object(soap_service, :sub_path => "operations"), :title => xlink_title("All operations for this SOAP Service")),
                        :resourceType => "SoapService"
    
  # <annotations>
  parent_xml.annotations xlink_attributes(uri_for_object(soap_service, :sub_path => "annotations"), :title => xlink_title("All annotations on this SOAP Service")),
                         :resourceType => "Annotations"

end