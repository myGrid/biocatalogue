# BioCatalogue: app/views/registries/api/_core_elements.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <dc:title>
dc_xml_tag parent_xml, :title, xlink_title(registry)

# <name>
parent_xml.name display_name(registry, false)

# <dc:description>
dc_xml_tag parent_xml, :description, registry.preferred_description

# <homepage>
parent_xml.homepage registry.homepage

# <dcterms:created>
dcterms_xml_tag parent_xml, :created, registry.created_at
