# BioCatalogue: app/views/service_tests/api/_related_links.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <related>
parent_xml.related do
    
  # <results>
  parent_xml.results xlink_attributes(uri_for_object(service_test, :sub_path => "results"), :title => xlink_title("Test results for this service test")),
    :resourceType => "TestResults"

end