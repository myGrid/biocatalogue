# BioCatalogue: app/views/services/api/_core_elements.xml.builder
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <name>
parent_xml.name display_name(service)

# <submitter>
parent_xml.submitter xlink_attributes(uri_for_object(service.submitter), :title => xlink_title(service.submitter)), 
                     :submitterType => service.submitter_type do
  parent_xml.name service.submitter_name
end

# <created>
dcterms_xml_tags(parent_xml, :created => service.created_at)