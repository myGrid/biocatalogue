# BioCatalogue: app/views/rest_parameters/api/_core_elements.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <dc:title>
dc_xml_tag parent_xml, :title, xlink_title(rest_parameter)

# <name>
parent_xml.name rest_parameter.name

# <description>
dc_xml_tag parent_xml, :description, rest_parameter.description

# <computationalType>
parent_xml.computationalType rest_parameter.computational_type

# <defaultValue>
parent_xml.defaultValue rest_parameter.default_value

# <paramStyle>
parent_xml.paramStyle rest_parameter.param_style

# <isOptional>
parent_xml.isOptional !rest_parameter.required

# <constrainedValues>
parent_xml.constrainedValues do |xml_node|
  rest_parameter.constrained_options.each { |value| xml_node.value value unless value.blank? }
end

# <submitter>
parent_xml.submitter xlink_attributes(uri_for_object(rest_parameter.submitter), :title => xlink_title(rest_parameter.submitter)), 
                     :resourceType => rest_parameter.submitter_type,
                     :resourceName => rest_parameter.submitter_name

# <dcterms:created>
dcterms_xml_tag parent_xml, :created, rest_parameter.created_at
