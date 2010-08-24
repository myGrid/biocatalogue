# BioCatalogue: app/views/tags/api/_related_links.xml.builder
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <related>
parent_xml.related do
  
  # <services>
  parent_xml.services xlink_attributes(generate_include_filter_url(:tag, tag_name, "services"), :title => xlink_title("List of filtered services that have the tag '#{tag_name}' somewhere within the service")),
                      :resourceType => "Services"
  
  # <soapOperations>
  parent_xml.soapOperations xlink_attributes(generate_include_filter_url(:tag, tag_name, "soap_operations"), :title => xlink_title("List of filtered SOAP operations that have the tag '#{tag_name}' either on the operation itself or on inputs/outputs")),
                      :resourceType => "Services"

  # <restMethods>
  parent_xml.restMethods xlink_attributes(generate_include_filter_url(:tag, tag_name, "rest_methods"), :title => xlink_title("List of filtered REST methods that have the tag '#{tag_name}' either on the method(endpoint) itself or on inputs/outputs")),
                      :resourceType => "Services"
                      
end