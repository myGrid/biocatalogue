# BioCatalogue: app/views/services/show.xml.builder
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
  
  # <deployments>
  xml.deployments xlink_attributes(uri_for_object(@service, :sub_path => "deployments")) do
    
    @service.service_deployments.each do |service_deployment|
      
      # <deployment>
      xml.deployment xlink_attributes(uri_for_object(service_deployment)) do
        
        # <endpoint>
        xml.endpoint service_deployment.endpoint
        
        # <provider>
        xml.provider xlink_attributes(uri_for_object(service_deployment.provider), :title => xlink_title(service_deployment.provider)) do
          xml.name service_deployment.provider.name   
        end
        
        if service_deployment.has_location_info?
          # <location>
          xml.location do 
            xml.city service_deployment.city
            xml.country service_deployment.country
          end
        end
        
        # <submitter>
        xml.submitter xlink_attributes(uri_for_object(service_deployment.submitter), :title => xlink_title(service_deployment.submitter)), 
                      :submitterType => service_deployment.submitter_type do
          xml.name service_deployment.submitter_name
        end
        
      end
      
    end
    
  end
  
  # <versions>
  xml.versions xlink_attributes(uri_for_object(@service, :sub_path => "versions")) do 
    
    @service.service_versions.each do |service_version|
      
      # <version>
      xml.version xlink_attributes(uri_for_object(service_version)),
                  :versionNumber => service_version.version,
                  :versionNumberDisplayText => service_version.version_display_text do 
        
        # <instance>
        xml.instance xlink_attributes(uri_for_object(service_version.service_versionified), :title => xlink_title(service_version.service_versionified)),
                     :serviceType => service_version.service_versionified.service_type_name do
          xml.name service_version.service_versionified.name
        end
        
        # <submitter>
        xml.submitter xlink_attributes(uri_for_object(service_version.submitter), :title => xlink_title(service_version.submitter)), 
                      :submitterType => service_version.submitter_type do
          xml.name service_version.submitter_name
        end
        
      end
      
    end
    
  end
  
  # <annotations>
  xml.annotations xlink_attributes(uri_for_object(@service, :sub_path => "annotations")) do
    
    BioCatalogue::Annotations.group_by_attribute_names(@service.annotations).each do |attribute_name, annotations|
    
      # <annotation> *
      
      annotations.each do |ann|
        
        xml.annotation xlink_attributes(uri_for_object(ann)), :version => ann.version  do 
          
          # <attribute>
          xml.attribute xlink_attributes(uri_for_object(ann.attribute)),
                        :name => attribute_name
          
          # <value>
          xml.value :type => ann.value_type do
            xml.cdata!(ann.value)
          end
             
          # <source>
          xml.source xlink_attributes(uri_for_object(ann.source), :title => xlink_title(ann.source)),
                     :sourceType => ann.source_type do
            xml.name ann.source.annotation_source_name
          end
          
          # <created>
          # <modified>
          dcterms_xml_tags(xml, :created => ann.created_at, :modified => ann.updated_at)
          
        end
        
      end
    
    end
    
  end
  
  # <monitoring>
  xml.monitoring do
    
    # <overall>
    
    # <tests>
    
    
  end
  
  # <related>
  xml.related do
    
    # <summary>
    xml.summary xlink_attributes(uri_for_object(@service, :sub_path => "summary"), :title => xlink_title("Summary view of Service - #{@service.name}"))
    
  end
  
end

