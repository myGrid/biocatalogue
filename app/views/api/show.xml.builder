# BioCatalogue: app/views/api/show.xml.builder
#
# Copyright (c) 2008-2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <?xml>
xml.instruct! :xml

# <services>
xml.tag! "api", { :resource => BioCatalogue::RestApi::Resources.uri_for_collection("/") }, BioCatalogue::RestApi::Builder.root_attributes do
  
  # <documentation>
  xml.documentation :href => "http://www.example.com"
  
  # <resources>
  xml.resources do
    
    # <services>
    xml.services :resource => BioCatalogue::RestApi::Resources.uri_for_collection("services")
    
    # <servicesFilters>
    xml.servicesFilters :resource => BioCatalogue::RestApi::Resources.uri_for_collection("services/filters")
    
    # <search>
    xml.search :resource => BioCatalogue::RestApi::Resources.uri_for_collection("search")
    
  end
  
end