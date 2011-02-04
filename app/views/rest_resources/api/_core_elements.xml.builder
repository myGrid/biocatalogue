# BioCatalogue: app/views/rest_resources/api/_core_elements.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <dc:title>
dc_xml_tag parent_xml, :title, xlink_title(rest_resource)

# <name>
parent_xml.path rest_resource.path

# <submitter>
parent_xml.submitter xlink_attributes(uri_for_object(rest_resource.submitter), 
                     :title => xlink_title(rest_resource.submitter)), 
                     :resourceType => rest_resource.submitter_type,
                     :resourceName => rest_resource.submitter_name

# <dcterms:created>
dcterms_xml_tag parent_xml, :created, rest_resource.created_at

# <archived>
if rest_resource.archived?
  parent_xml.archived rest_resource.archived_at.iso8601
end