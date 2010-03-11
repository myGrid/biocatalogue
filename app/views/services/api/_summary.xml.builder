# BioCatalogue: app/views/services/api/_summary.xml.builder
#
# Copyright (c) 2009-2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <summary>
parent_xml.tag! "summary",
                xlink_attributes(uri_for_object(service, :sub_path => "summary")),
                :resourceType => "Service" do 
    
  # <counts>
  parent_xml.counts do
    
    # <deployments>
    parent_xml.deployments service.service_deployments.count
    
    # <variants>
    parent_xml.variants service.service_versions.count
    
    # <metadata> *
    metadata_counts_for_service(service).each do |m_type, m_count|
      parent_xml.metadata m_count, :by => m_type
    end
    
  end
  
  # <alternativeName> *
  all_alternative_name_annotations_for_service(service).each do |ann|
    parent_xml.alternativeName ann.value
  end
  
  # <category> *
  service.annotations_with_attribute("category").each do |category_annotation|
    unless (category = Category.find_by_id(category_annotation.value)).nil?
      parent_xml.category category.name, xlink_attributes(uri_for_object(category), :title => xlink_title(category)), :resourceType => "Category"
    end
  end
  
  # <provider> *
  service.service_deployments.each do |service_deployment|
    parent_xml.provider xlink_attributes(uri_for_object(service_deployment.provider), :title => xlink_title(service_deployment.provider)), :resourceType => "ServiceProvider" do
      parent_xml.name display_name(service_deployment.provider, false)   
    end
  end
  
  # <endpoint> *
  service.service_deployments.each do |service_deployment|
    parent_xml.endpoint service_deployment.endpoint
  end
  
  # <wsdl> *
  unless (soap_services = service.service_version_instances_by_type("SoapService")).blank?
    soap_services.each do |soap_service|
      parent_xml.wsdl soap_service.wsdl_location
    end
  end
  
  # <location> *
  service.service_deployments.each do |service_deployment|
    render :partial => "api/location", :locals => { :parent_xml => parent_xml, :city => service_deployment.city, :country => service_deployment.country }      
  end
  
  # <documentationUrl> *
  service.service_version_instances.each do |service_instance|
    service_instance.annotations_with_attribute("documentation_url").each do |ann|
      parent_xml.documentationUrl ann.value 
    end
  end
  
  # <dc:description> *
  service.service_version_instances.each do |service_instance|
  
    unless (desc = service_instance.description).blank?
      dc_xml_tag parent_xml, :description, desc
    end
    
    service_instance.annotations_with_attribute("description").each do |ann|
      dc_xml_tag parent_xml, :description, ann.value
    end
      
  end
  
  # <tag> *
  BioCatalogue::Annotations.get_tag_annotations_for_annotatable(service).each do |ann|
    parent_xml.tag ann.value, xlink_attributes(uri_for_path(BioCatalogue::Tags.generate_tag_show_uri(ann.value)), :title => xlink_title("Tag - #{ann.value}")), :resourceType => "Tag"
  end
  
  # <cost> *
  service.service_deployments.each do |service_deployment|
    service_deployment.annotations_with_attribute("cost").each do |ann|
      parent_xml.cost ann.value 
    end
  end
  
  # <license> *
  service.service_version_instances.each do |service_instance|
    service_instance.annotations_with_attribute("license").each do |ann|
      parent_xml.license ann.value
    end
  end

  # <usageCondition> *
  service.service_deployments.each do |service_deployment|
    service_deployment.annotations_with_attribute("usage_condition").each do |ann|
      parent_xml.usageCondition ann.value 
    end
  end

  # <contact> *
  service.service_deployments.each do |service_deployment|
    service_deployment.annotations_with_attribute("contact").each do |ann|
      parent_xml.contact ann.value 
    end
  end
  
  # <publication> *
  service.service_version_instances.each do |service_instance|
    service_instance.annotations_with_attribute("publication").each do |ann|
      parent_xml.publication ann.value 
    end
  end

  # <citation> *
  service.service_version_instances.each do |service_instance|
    service_instance.annotations_with_attribute("citation").each do |ann|
      parent_xml.citation ann.value 
    end
  end
  
end