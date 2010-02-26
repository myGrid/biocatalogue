# BioCatalogue: app/views/soap_services/api/_operations.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <operations>
parent_xml.tag! "operations",
                xlink_attributes(uri_for_object(soap_service, :sub_path => "operations")),
                :resourceType => "SoapService" do
                  
  soap_service.soap_operations.each do |op|
    # <soapOperation>
    render :partial => "soap_operations/api/inline_item", :locals => { :parent_xml => parent_xml, :soap_operation => op }
  end
  
end