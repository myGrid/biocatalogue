# BioCatalogue: app/views/soap_services/api/_core_elements.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <dc:title>
dc_xml_tag parent_xml, :title, xlink_title(soap_service)

# <name>
parent_xml.name display_name(soap_service, false)

# <wsdlLocation>
parent_xml.wsdlLocation soap_service.wsdl_location

# <submitter>
parent_xml.submitter xlink_attributes(uri_for_object(soap_service.service_version.submitter), :title => xlink_title(soap_service.service_version.submitter)), 
              :resourceType => soap_service.service_version.submitter_type,
              :resourceName => soap_service.service_version.submitter_name

# <description>
dc_xml_tag parent_xml, :description, soap_service.preferred_description

# <documentationUrl>
parent_xml.documentationUrl soap_service.preferred_documentation_url

# <dcterms:created>
dcterms_xml_tag parent_xml, :created, soap_service.created_at
