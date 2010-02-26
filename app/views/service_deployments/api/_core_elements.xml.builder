# BioCatalogue: app/views/service_deployments/api/_core_elements.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <endpoint>
parent_xml.endpoint service_deployment.endpoint

# <provider>
render :partial => "service_providers/api/inline_item", 
       :locals => { :parent_xml => parent_xml, :service_provider => service_deployment.provider }

# <location>
render :partial => "api/location", :locals => { :parent_xml => parent_xml, :city => service_deployment.city, :country => service_deployment.country }

# <submitter>
parent_xml.submitter xlink_attributes(uri_for_object(service_deployment.submitter), :title => xlink_title(service_deployment.submitter)), 
                     :resourceType => service_deployment.submitter_type,
                     :resourceName => service_deployment.submitter_name

# <dcterms:created>
dcterms_xml_tag parent_xml, :created, service_deployment.created_at
