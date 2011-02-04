# BioCatalogue: app/views/services/api/_core_elements.xml.builder
#
# Copyright (c) 2009-2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <dc:title>
dc_xml_tag parent_xml, :title, xlink_title(service)

# <name>
parent_xml.name display_name(service, false)

# <specifiedName>
#parent_xml.specifiedName service.name

# <originalSubmitter>
parent_xml.originalSubmitter xlink_attributes(uri_for_object(service.submitter), :title => xlink_title(service.submitter)), 
                     :resourceType => service.submitter_type,
                     :resourceName => service.submitter_name

# <dc:description>
dc_xml_tag parent_xml, :description, service.preferred_description

# <serviceTechnologyTypes>
parent_xml.serviceTechnologyTypes do 
  # <type> *
  service.service_types.each do |s_type|
    parent_xml.type s_type
  end
end

# <latestMonitoringStatus>
render :partial => "monitoring/api/status", 
       :locals => { :parent_xml => parent_xml, 
                    :element_name => "latestMonitoringStatus", 
                    :status => service.latest_status }

# <dcterms:created>
dcterms_xml_tag parent_xml, :created, service.created_at

# <archived>
if service.archived?
  parent_xml.archived service.archived_at.iso8601
end