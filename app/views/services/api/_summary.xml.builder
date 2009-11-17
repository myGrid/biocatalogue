# BioCatalogue: app/views/services/api/_summary.xml.builder
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

parent_xml.summary xlink_attributes(uri_for_object(service, :sub_path => "summary")) do 
    
  # <counts>
  parent_xml.counts do
    
    # <deployments>
    parent_xml.deployments service.service_deployments.count
    
    # <versions>
    parent_xml.versions service.service_versions.count
    
    # <metadata> *
    metadata_counts_for_service(service).each do |m_type, m_count|
      parent_xml.metadata m_count, :by => m_type
    end
    
  end
  
  # <alternativeNames>
  parent_xml.alternativeNames do 
    
    # <alternativeName> *
    all_alternative_name_annotations_for_service(service).each do |ann|
      parent_xml.alternativeName ann.value
    end
    
  end
  
  # <serviceTypes>
  parent_xml.serviceTypes do
    service.service_types.each do |s_type|
      # <serviceType>
      parent_xml.serviceType s_type
    end
  end
  
  # <categories>
  parent_xml.categories do
    # <category> *
    service.annotations_with_attribute("category").each do |category_annotation|
      unless (category = Category.find_by_id(category_annotation.value)).nil?
        parent_xml.category category.name
      end
    end
  end
  
  # <providers>
  parent_xml.providers do
    # <provider> *
    service.service_deployments.each do |service_deployment|
      parent_xml.provider xlink_attributes(uri_for_object(service_deployment.provider), :title => xlink_title(service_deployment.provider)) do
        parent_xml.name service_deployment.provider.name   
      end
    end
  end
  
  # <endpoints>
  parent_xml.endpoints do
    # <endpoint> *
    service.service_deployments.each do |service_deployment|
      parent_xml.endpoint service_deployment.endpoint
    end
  end
  
  unless (soap_services = service.service_version_instances_by_type("SoapService")).blank?
    # <wsdls>
    parent_xml.wsdls do 
      # <wsdl> *
      soap_services.each do |soap_service|
        parent_xml.wsdl soap_service.wsdl_location
      end
    end
  end
  
  # <locations>
  parent_xml.locations do
    # <location> *
    service.service_deployments.each do |service_deployment|
      if service_deployment.has_location_info?
        parent_xml.location :city => service_deployment.city, :country => service_deployment.country  
      end
    end
  end
  
  # <descriptions>
  parent_xml.descriptions do 
    # <description> *
    service.service_version_instances.each do |service_instance|
    
      unless (desc = service_instance.description).blank?
        parent_xml.description do
          parent_xml.cdata!(desc)
        end
      end
      
      service_instance.annotations_with_attribute("description").each do |ann|
        parent_xml.description do 
          parent_xml.cdata!(ann.value)
        end
      end
        
    end
  end
  
  # <tags>
  parent_xml.tags do
    # <tag> *
    BioCatalogue::Annotations.get_tag_annotations_for_annotatable(service).each do |ann|
      parent_xml.tag do 
        parent_xml.cdata!(ann.value)
      end
    end
  end
  
end