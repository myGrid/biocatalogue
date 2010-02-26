# BioCatalogue: app/views/soap_outputs/api/_core_elements.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <dc:title>
dc_xml_tag parent_xml, :title, xlink_title(soap_output)

# <name>
parent_xml.name soap_output.name

# <description>
dc_xml_tag parent_xml, :description, soap_output.description

# <computationalType>
parent_xml.computationalType soap_output.computational_type

# <computationalTypeDetails>
parent_xml.computationalTypeDetails soap_output.computational_type_details.blank? ? "" : soap_output.computational_type_details.inspect

# <dcterms:created>
dcterms_xml_tag parent_xml, :created, soap_output.created_at
