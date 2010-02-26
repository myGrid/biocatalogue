# BioCatalogue: app/views/soap_operations/api/_inputs.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <inputs>
parent_xml.tag! "inputs", 
                xlink_attributes(uri_for_object(soap_operation, :sub_path => "inputs")),
                :resourceType => "SoapOperation" do
                  
  soap_operation.soap_inputs.each do |input|
    # <soapInput>
    render :partial => "soap_inputs/api/inline_item", :locals => { :parent_xml => parent_xml, :soap_input => input }
  end
  
end