# BioCatalogue: app/views/api/show.xml.builder
#
# Copyright (c) 2008-2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <?xml>
xml.instruct! :xml

# <services>
xml.tag! "biocatalogue", xlink_attributes(uri_for_collection("/")), xml_root_attributes do
  
  # <documentation>
  xml.documentation "xlink:href" => "http://www.example.com"
  
  # <resources>
  xml.resources do
    
    # <services>
    xml.services xlink_attributes(uri_for_collection("services"),
                                  :title => xlink_title("Services index"))
    
    # <servicesFilters>
    xml.servicesFilters xlink_attributes(uri_for_collection("services/filters"),
                                         :title => xlink_title("Filters for the services index"))
    
    # <search>
    xml.search xlink_attributes(uri_for_collection("search"),
                                :title => xlink_title("Search everything in the BioCatalogue"))
    
  end
  
end