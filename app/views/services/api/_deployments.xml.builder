# BioCatalogue: app/views/services/api/_deployments.xml.builder
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

parent_xml.deployments xlink_attributes(uri_for_object(service, :sub_path => "deployments")) do
    
  service.service_deployments.each do |service_deployment|
    
    # <deployment>
    parent_xml.deployment xlink_attributes(uri_for_object(service_deployment)) do
      
      # <endpoint>
      parent_xml.endpoint service_deployment.endpoint
      
      # <provider>
      parent_xml.provider xlink_attributes(uri_for_object(service_deployment.provider), :title => xlink_title(service_deployment.provider)) do
        parent_xml.name service_deployment.provider.name   
      end
      
      if service_deployment.has_location_info?
        # <location>
        parent_xml.location do 
          parent_xml.city service_deployment.city
          parent_xml.country service_deployment.country
        end
      end
      
      # <submitter>
      parent_xml.submitter xlink_attributes(uri_for_object(service_deployment.submitter), :title => xlink_title(service_deployment.submitter)), 
                           :submitterType => service_deployment.submitter_type do
        parent_xml.name service_deployment.submitter_name
      end
      
    end
    
  end
  
end