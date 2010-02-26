# BioCatalogue: app/views/users/api/_related_links.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <related>
parent_xml.related do
    
  # <annotationsBy>
  parent_xml.annotationsBy xlink_attributes(uri_for_object(user, :sub_path => "annotations_by"), :title => xlink_title("All annotations by this User - #{display_name(user, false)}")),
                           :resourceType => "Annotations"
  
  # <services>
  parent_xml.services xlink_attributes(uri_for_object(user, :sub_path => "services"), :title => xlink_title("All services that this User - #{display_name(user, false)} - has submitted")),
                      :resourceType => "Services"
  
end