# BioCatalogue: app/views/services/api/_related_links_for_service.xml.builder
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

parent_xml.related do
    
  # <summary>
  parent_xml.summary xlink_attributes(uri_for_object(service, :sub_path => "summary"), :title => xlink_title("Summary view of Service - #{display_name(service)}"))
  
  # <annotations>
  parent_xml.annotations xlink_attributes(uri_for_object(service, :sub_path => "annotations"), :title => xlink_title("All annotations for this Service (#{display_name(service)}) and it's deployments and versions"))
  
  # <deployments>
  parent_xml.deployments xlink_attributes(uri_for_object(service, :sub_path => "deployments"), :title => xlink_title("All deployments for Service - #{display_name(service)}"))
  
  # <versions>
  parent_xml.versions xlink_attributes(uri_for_object(service, :sub_path => "versions"), :title => xlink_title("All versions for Service - #{display_name(service)}"))
  
  # <monitoring>
  parent_xml.monitoring xlink_attributes(uri_for_object(service, :sub_path => "monitoring"), :title => xlink_title("Monitoring results for Service - #{display_name(service)}"))
  
end