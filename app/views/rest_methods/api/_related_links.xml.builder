# BioCatalogue: app/views/rest_methods/api/_related_links.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <related>
parent_xml.related do
    
  # <inputs>
  parent_xml.inputs xlink_attributes(uri_for_object(rest_method, :sub_path => "inputs"), :title => xlink_title("All REST Inputs on this REST endpoint")),
                                  :resourceType => "RestMethod"

  # <outputs>
  parent_xml.outputs xlink_attributes(uri_for_object(rest_method, :sub_path => "outputs"), :title => xlink_title("All REST Outputs on this REST endpoint")),
                                   :resourceType => "RestMethod"
  
  # <annotations>
  parent_xml.annotations xlink_attributes(uri_for_object(rest_method, :sub_path => "annotations"), :title => xlink_title("All annotations on this REST endpoint")),
                         :resourceType => "Annotations"
  
end