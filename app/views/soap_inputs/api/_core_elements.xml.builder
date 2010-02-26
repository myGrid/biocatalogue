# BioCatalogue: app/views/soap_inputs/api/_core_elements.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <dc:title>
dc_xml_tag parent_xml, :title, xlink_title(soap_input)

# <name>
parent_xml.name soap_input.name

# <description>
dc_xml_tag parent_xml, :description, soap_input.description

# <computationalType>
parent_xml.computationalType soap_input.computational_type

# <computationalTypeDetails>
parent_xml.computationalTypeDetails soap_input.computational_type_details.blank? ? "" : soap_input.computational_type_details.inspect

# <dcterms:created>
dcterms_xml_tag parent_xml, :created, soap_input.created_at
