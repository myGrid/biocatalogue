# BioCatalogue: app/views/services/api/_related_links.xml.builder
#
# Copyright (c) 2009-2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <related>
parent_xml.related do
  
  # <withSummary>
  parent_xml.withSummary xlink_attributes(uri_for_object(service, :params => { :include => "summary" }), :title => xlink_title("View of this Service including the summary section")),
                     :resourceType => "Service"
  
  # <withMonitoring>
  parent_xml.withMonitoring xlink_attributes(uri_for_object(service, :params => { :include => "monitoring" }), :title => xlink_title("View of this Service including the monitoring section")),
                        :resourceType => "Service"
  
  # <withAllSections>
  parent_xml.withAllSections xlink_attributes(uri_for_object(service, :params => { :include => "all" }), :title => xlink_title("A complete view of this Service which includes the summary, deployments, variants and monitoring")),
                     :resourceType => "Service"
  
  # <summary>
  parent_xml.summary xlink_attributes(uri_for_object(service, :sub_path => "summary"), :title => xlink_title("Just the summary of this Service")),
                         :resourceType => "Service"
  
  # <deployments>
  parent_xml.deployments xlink_attributes(uri_for_object(service, :sub_path => "deployments"), :title => xlink_title("Just the deployments for this Service")),
                         :resourceType => "Service"
  
  # <variants>
  parent_xml.variants xlink_attributes(uri_for_object(service, :sub_path => "variants"), :title => xlink_title("Just the variants (i.e.: SOAP and/or REST) for this Service")),
                         :resourceType => "Service"
  
  # <monitoring>
  parent_xml.monitoring xlink_attributes(uri_for_object(service, :sub_path => "monitoring"), :title => xlink_title("Just the monitoring info for this Service")),
                         :resourceType => "Service"
  
  # <annotations>
  parent_xml.annotations xlink_attributes(uri_for_object(service, :sub_path => "annotations"), :title => xlink_title("All annotations on this Service")),
                         :resourceType => "Annotations"
  
end