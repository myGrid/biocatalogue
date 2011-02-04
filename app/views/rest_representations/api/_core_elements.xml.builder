# BioCatalogue: app/views/rest_representations/api/_core_elements.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <dc:title>
dc_xml_tag parent_xml, :title, xlink_title(rest_representation)

# <description>
dc_xml_tag parent_xml, :description, rest_representation.description

# <contentType>
parent_xml.contentType rest_representation.content_type

# <submitter>
parent_xml.submitter xlink_attributes(uri_for_object(rest_representation.submitter), :title => xlink_title(rest_representation.submitter)), 
                     :resourceType => rest_representation.submitter_type,
                     :resourceName => rest_representation.submitter_name

# <dcterms:created>
dcterms_xml_tag parent_xml, :created, rest_representation.created_at

# <archived>
if rest_representation.archived?
  parent_xml.archived rest_representation.archived_at.iso8601
end