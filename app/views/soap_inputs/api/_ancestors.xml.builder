# BioCatalogue: app/views/soap_inputs/api/_ancestors.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <ancestors>
parent_xml.ancestors do
  
  # <service>
  render :partial => "services/api/inline_item", :locals => { :parent_xml => parent_xml, :service => soap_input.associated_service }
  
  # <soapService>
  render :partial => "soap_services/api/inline_item", :locals => { :parent_xml => parent_xml, :soap_service => soap_input.soap_operation.soap_service }
  
  # <soapOperation>
  render :partial => "soap_operations/api/inline_item", :locals => { :parent_xml => parent_xml, :soap_operation => soap_input.soap_operation }
    
end