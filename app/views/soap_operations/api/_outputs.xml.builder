# BioCatalogue: app/views/soap_operations/api/_outputs.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <outputs>
parent_xml.tag! "outputs",
                xlink_attributes(uri_for_object(soap_operation, :sub_path => "outputs")),
                :resourceType => "SoapOperation" do
  
  soap_operation.soap_outputs.each do |output|
    # <soapOutput>
    render :partial => "soap_outputs/api/inline_item", :locals => { :parent_xml => parent_xml, :soap_output => output }
  end
  
end