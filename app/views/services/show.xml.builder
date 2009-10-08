# BioCatalogue: app/views/services/show.xml.builder
#
# Copyright (c) 2008-2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <?xml>
xml.instruct! :xml

# <service>
xml.tag! "service", 
         { :resource => BioCatalogue::RestApi::Resources.uri_for_object(@service, :params => params) }, 
         BioCatalogue::RestApi::Builder.root_attributes do
  
  # <name>
  xml.name display_name(@service)
  
  # <submitter>
  xml.submitter @service.submitter_name,
                :resource => BioCatalogue::RestApi::Resources.uri_for_object(@service.submitter), 
                :sourceType => @service.submitter_type
  
  # <createdAt>
  xml.createdAt @service.created_at.iso8601
  
  # <deployments>
  xml.deployments :resource => BioCatalogue::RestApi::Resources.uri_for_object(@service, :sub_path => "deployments") do
    
    @service.service_deployments.each do |service_deployment|
      
      # <deployment>
      xml.deployment :resource => BioCatalogue::RestApi::Resources.uri_for_object(service_deployment) do
        
        # <endpoint>
        xml.endpoint service_deployment.endpoint
        
        # <provider>
        xml.provider service_deployment.provider.name, 
                     :resource => BioCatalogue::RestApi::Resources.uri_for_object(service_deployment.provider)
        
        # <location>
        xml.location do 
          xml.city service_deployment.city
          xml.country service_deployment.country
        end
        
        # <submitter>
        xml.submitter service_deployment.submitter_name,
                      :resource => BioCatalogue::RestApi::Resources.uri_for_object(service_deployment.submitter), 
                      :sourceType => service_deployment.submitter_type
        
      end
      
    end
    
  end
  
  # <versions>
  xml.versions :resource => BioCatalogue::RestApi::Resources.uri_for_object(@service, :sub_path => "versions") do 
    
    @service.service_versions.each do |service_version|
      
      # <version>
      xml.version :resource => BioCatalogue::RestApi::Resources.uri_for_object(service_version),
                  :versionNumber => service_version.version,
                  :versionDisplayText => service_version.version_display_text do 
        
        # <instance>
        xml.instance nil, 
                     :resource => BioCatalogue::RestApi::Resources.uri_for_object(service_version.service_versionified),
                     :serviceType => service_version.service_versionified.service_type_name
        
        # <submitter>
        xml.submitter service_version.submitter_name,
                      :resource => BioCatalogue::RestApi::Resources.uri_for_object(service_version.submitter), 
                      :sourceType => service_version.submitter_type
        
      end
      
    end
    
  end
  
  # <annotations>
  xml.annotations :resource => BioCatalogue::RestApi::Resources.uri_for_object(@service, :sub_path => "annotations") do
    
    BioCatalogue::Annotations.group_by_attribute_names(@service.annotations).each do |attribute_name, annotations|
    
      # <annotation> *
      
      annotations.each do |ann|
        
        xml.annotation :resource => BioCatalogue::RestApi::Resources.uri_for_object(ann), :version => ann.version  do 
          
          # <attribute>
          xml.attribute nil, :name => attribute_name
          
          # <value>
          xml.value :type => ann.value_type do
            xml.cdata!(ann.value)
          end
             
          # <source>
          xml.source ann.source.annotation_source_name,
                     :resource => BioCatalogue::RestApi::Resources.uri_for_object(ann.source), 
                     :sourceType => ann.source_type
          
          # <createdAt>
          xml.createdAt ann.created_at.iso8601
          
          # <updatedAt>
          xml.updatedAt ann.updated_at.iso8601
          
        end
        
      end
    
    end
    
  end
  
  # <related>
  xml.related do
    
    # <summary>
    xml.summary :resource => BioCatalogue::RestApi::Resources.uri_for_object(@service, :sub_path => "summary")
    
  end
  
end

