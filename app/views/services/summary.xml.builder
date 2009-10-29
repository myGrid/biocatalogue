# BioCatalogue: app/views/services/summary.xml.builder
#
# Copyright (c) 2008-2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <?xml>
xml.instruct! :xml

# <service>
xml.tag! "service", 
         xlink_attributes(uri_for_object(@service, :params => params)), 
         xml_root_attributes do
  
  render :partial => "core_elements", :locals => { :parent_xml => xml }
  
  # <summary>
  xml.summary xlink_attributes(uri_for_object(@service, :sub_path => "summary")) do 
    
    # <counts>
    xml.counts do
      
      # <deployments>
      xml.deployments @service.service_deployments.count
      
      # <versions>
      xml.versions @service.service_versions.count
      
      # <metadata> *
      metadata_counts_for_service(@service).each do |m_type, m_count|
        xml.metadata m_count, :by => m_type
      end
      
    end
    
    # <alternativeNames>
    xml.alternativeNames do 
      
      # <alternativeName> *
      all_name_annotations_for_service(@service).each do |ann|
        xml.alternativeName ann.value
      end
      
    end
    
    # <serviceTypes>
    xml.serviceTypes do
      @service.service_types.each do |s_type|
        # <serviceType>
        xml.serviceType s_type
      end
    end
    
    # <categories>
    xml.categories do
      # <category> *
      @service.annotations_with_attribute("category").each do |category_annotation|
        unless (category = Category.find_by_id(category_annotation.value)).nil?
          xml.category category.name
        end
      end
    end
    
    # <providers>
    xml.providers do
      # <provider> *
      @service.service_deployments.each do |service_deployment|
        xml.provider xlink_attributes(uri_for_object(service_deployment.provider), :title => xlink_title(service_deployment.provider)) do
          xml.name service_deployment.provider.name   
        end
      end
    end
    
    # <endpoints>
    xml.endpoints do
      # <endpoint> *
      @service.service_deployments.each do |service_deployment|
        xml.endpoint service_deployment.endpoint
      end
    end
    
    unless (soap_services = @service.service_version_instances_by_type("SoapService")).blank?
      # <wsdls>
      xml.wsdls do 
        # <wsdl> *
        soap_services.each do |soap_service|
          xml.wsdl soap_service.wsdl_location
        end
      end
    end
    
    # <locations>
    xml.locations do
      # <location> *
      @service.service_deployments.each do |service_deployment|
        if service_deployment.has_location_info?
          xml.location :city => service_deployment.city, :country => service_deployment.country  
        end
      end
    end
    
    # <descriptions>
    xml.descriptions do 
      # <description> *
      @service.service_version_instances.each do |service_instance|
      
        unless (desc = service_instance.description).blank?
          xml.description do
            xml.cdata!(desc)
          end
        end
        
        service_instance.annotations_with_attribute("description").each do |ann|
          xml.description do 
            xml.cdata!(ann.value)
          end
        end
          
      end
    end
    
    # <tags>
    xml.tags do
      # <tag> *
      BioCatalogue::Annotations.get_tag_annotations_for_annotatable(@service).each do |ann|
        xml.tag do 
          xml.cdata!(ann.value)
        end
      end
    end
    
  end
  
  # <related>
  xml.related do
    
  end
  
end