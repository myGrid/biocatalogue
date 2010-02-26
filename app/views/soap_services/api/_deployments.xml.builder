# BioCatalogue: app/views/soap_services/api/_deployments.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <deployments>
parent_xml.tag! "deployments",
                xlink_attributes(uri_for_object(soap_service, :sub_path => "deployments")),
                :resourceType => "SoapService" do
                  
  soap_service.service_deployments.each do |service_deployment|
    # <serviceDeployment>
    render :partial => "service_deployments/api/inline_item", :locals => { :parent_xml => parent_xml, :service_deployment => service_deployment }
  end
  
end