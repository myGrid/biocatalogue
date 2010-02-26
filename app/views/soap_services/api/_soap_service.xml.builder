# BioCatalogue: app/views/soap_services/api/_soap_service.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# Defaults:
is_root = false unless local_assigns.has_key?(:is_root)
show_core = true unless local_assigns.has_key?(:show_core)
show_deployments = false unless local_assigns.has_key?(:show_deployments)
show_operations = false unless local_assigns.has_key?(:show_operations)
show_ancestors = false unless local_assigns.has_key?(:show_ancestors)
show_related = false unless local_assigns.has_key?(:show_related)

# <soapService>
parent_xml.tag! "soapService",
                xlink_attributes(uri_for_object(soap_service), :title => xlink_title(soap_service)).merge(is_root ? xml_root_attributes : {}),
                :resourceType => "SoapService" do
  
  # Core elements
  if show_core
    render :partial => "soap_services/api/core_elements", :locals => { :parent_xml => parent_xml, :soap_service => soap_service }
  end
  
  # <deployments>
  if show_deployments
    render :partial => "soap_services/api/deployments", :locals => { :parent_xml => parent_xml, :soap_service => soap_service }
  end
  
  # <operations>
  if show_operations
    render :partial => "soap_services/api/operations", :locals => { :parent_xml => parent_xml, :soap_service => soap_service }
  end
  
  # <ancestors>
  if show_ancestors
    render :partial => "soap_services/api/ancestors", :locals => { :parent_xml => parent_xml, :soap_service => soap_service }
  end
  
  # <related>
  if show_related
    render :partial => "soap_services/api/related_links", :locals => { :parent_xml => parent_xml, :soap_service => soap_service }
  end
  
end
