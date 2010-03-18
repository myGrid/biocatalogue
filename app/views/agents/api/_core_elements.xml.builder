# BioCatalogue: app/views/agents/api/_core_elements.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <dc:title>
dc_xml_tag parent_xml, :title, xlink_title(agent)

# <name>
parent_xml.name display_name(agent, false)

# <dc:description>
dc_xml_tag parent_xml, :description, agent.preferred_description

# <dcterms:created>
dcterms_xml_tag parent_xml, :created, agent.created_at
