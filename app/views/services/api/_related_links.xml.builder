# BioCatalogue: app/views/services/api/_related_links.xml.builder
#
# Copyright (c) 2009-2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <related>
parent_xml.related do
  
  # <withAllSections>
  parent_xml.withAllSections xlink_attributes(uri_for_object(service, :params => { :include => "all" }), :title => xlink_title("A complete view of this Service - #{display_name(service, false)} - which includes the summary, deployments, variants and monitoring")),
                     :resourceType => "Service"
                     
  # <summary>
  parent_xml.summary xlink_attributes(uri_for_object(service, :sub_path => "summary"), :title => xlink_title("Summary view of Service - #{display_name(service, false)}")),
                     :resourceType => "Service"
  
  # <deployments>
  parent_xml.deployments xlink_attributes(uri_for_object(service, :sub_path => "deployments"), :title => xlink_title("All deployments for Service - #{display_name(service, false)}")),
                         :resourceType => "Service"
  
  # <variants>
  parent_xml.variants xlink_attributes(uri_for_object(service, :sub_path => "variants"), :title => xlink_title("All variants (eg: SOAP, REST) available for Service - #{display_name(service, false)}")),
                      :resourceType => "Service"
  
  # <annotations>
  parent_xml.annotations xlink_attributes(uri_for_object(service, :sub_path => "annotations"), :title => xlink_title("All annotations on this Service - #{display_name(service, false)}")),
                         :resourceType => "Annotations"
  
  # <monitoring>
  parent_xml.monitoring xlink_attributes(uri_for_object(service, :sub_path => "monitoring"), :title => xlink_title("Monitoring information for Service - #{display_name(service, false)}")),
                        :resourceType => "Service"
  
end