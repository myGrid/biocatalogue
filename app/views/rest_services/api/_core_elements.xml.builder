# BioCatalogue: app/views/rest_services/api/_core_elements.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <dc:title>
dc_xml_tag parent_xml, :title, xlink_title(rest_service)

# <name>
parent_xml.name display_name(rest_service, false)

# <submitter>
parent_xml.submitter xlink_attributes(uri_for_object(rest_service.service_version.submitter), :title => xlink_title(rest_service.service_version.submitter)), 
                     :resourceType => rest_service.service_version.submitter_type,
                     :resourceName => rest_service.service_version.submitter_name

# <description>
dc_xml_tag parent_xml, :description, rest_service.preferred_description

# <documentationUrl>
parent_xml.documentationUrl rest_service.preferred_documentation_url

# <dcterms:created>
dcterms_xml_tag parent_xml, :created, rest_service.created_at
