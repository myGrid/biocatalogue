# BioCatalogue: app/views/agents/api/_related_links.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <related>
parent_xml.related do
    
  # <annotations>
#  parent_xml.annotations xlink_attributes(uri_for_object(agent, :sub_path => "annotations"), :title => xlink_title("All annotations on this Agent - #{display_name(agent, false)}")),
#                         :resourceType => "Registry"
  
  # <annotationsBy>
  parent_xml.annotationsBy xlink_attributes(uri_for_object(agent, :sub_path => "annotations_by"), :title => xlink_title("All annotations by this Agent - #{display_name(agent, false)}")),
                           :resourceType => "Annotations"
  
end