# BioCatalogue: app/views/soap_services/wsdl_locations.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <?xml>
xml.instruct! :xml

# <wsdlLocations>
xml.tag! "wsdlLocations",
    xlink_attributes(uri_for_collection("soap_services/wsdl_locations", :params => params)),
    xml_root_attributes,
    :resourceType => "TestResults" do
  
  # <wsdlLocation> *
  @wsdl_locations.each do |w|
    xml.wsdlLocation w
  end

end