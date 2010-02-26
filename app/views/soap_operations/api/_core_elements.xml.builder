# BioCatalogue: app/views/soap_operations/api/_core_elements.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <dc:title>
dc_xml_tag parent_xml, :title, xlink_title(soap_operation)

# <name>
parent_xml.name soap_operation.name

# <description>
dc_xml_tag parent_xml, :description, soap_operation.description

# <parameterOrder>
parent_xml.parameterOrder soap_operation.parameter_order

# <dcterms:created>
dcterms_xml_tag parent_xml, :created, soap_operation.created_at
