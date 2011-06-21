# BioCatalogue: app/views/soap_inputs/api/_core_elements.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <dc:title>
dc_xml_tag parent_xml, :title, xlink_title(soap_input)

# <name>
parent_xml.name display_name(soap_input, false)

# <description>
dc_xml_tag parent_xml, :description, soap_input.preferred_description

# <computationalType>
parent_xml.computationalType soap_input.computational_type

# <computationalTypeDetails>
parent_xml.computationalTypeDetails soap_input.computational_type_details.blank? ? "" : soap_input.computational_type_details.inspect

# <dcterms:created>
dcterms_xml_tag parent_xml, :created, soap_input.created_at

# <archived>
if soap_input.archived?
  parent_xml.archived soap_input.archived_at.iso8601
end