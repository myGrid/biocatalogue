# BioCatalogue: app/views/rest_resources/api/_related_links.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <related>
parent_xml.related do
  
  # <restMethods>
  parent_xml.restMethods xlink_attributes(uri_for_object(rest_resource, :sub_path => "methods"), :title => xlink_title("The REST methods provided by this REST Resource - #{display_name(rest_resource, false)}")),
                         :resourceType => "RestResource"
    
  # <annotations>
  parent_xml.annotations xlink_attributes(uri_for_object(rest_resource, :sub_path => "annotations"), :title => xlink_title("All annotations on this REST Resource - #{display_name(rest_resource, false)}")),
                         :resourceType => "Annotations"
  
end