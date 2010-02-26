# BioCatalogue: app/views/service_providers/api/_core_elements.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <dc:title>
dc_xml_tag parent_xml, :title, xlink_title(service_provider)

# <name>
parent_xml.name display_name(service_provider, false)

# <dc:description>
dc_xml_tag parent_xml, :description, service_provider.preferred_description

# <dcterms:created>
dcterms_xml_tag parent_xml, :created, service_provider.created_at
