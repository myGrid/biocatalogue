# BioCatalogue: app/views/service_deployments/api/_service_deployment.xml.builder
#
# Copyright (c) 2009-2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# Defaults:
is_root = false unless local_assigns.has_key?(:is_root)
show_core = true unless local_assigns.has_key?(:show_core)
show_provided_variant = false unless local_assigns.has_key?(:show_provided_variant)
show_ancestors = false unless local_assigns.has_key?(:show_ancestors)
show_related = false unless local_assigns.has_key?(:show_related)

# <serviceDeployment>
parent_xml.tag! "serviceDeployment",
                xlink_attributes(uri_for_object(service_deployment)).merge(is_root ? xml_root_attributes : {}),
                :resourceType => "ServiceDeployment" do
  
  # Core elements
  if show_core
    render :partial => "service_deployments/api/core_elements", :locals => { :parent_xml => parent_xml, :service_deployment => service_deployment }
  end
  
  # <providedVariant>
  if show_provided_variant
    render :partial => "service_deployments/api/show_provided_variant", :locals => { :parent_xml => parent_xml, :service_deployment => service_deployment }
  end
  
  # <ancestors>
  if show_ancestors
    render :partial => "service_deployments/api/ancestors", :locals => { :parent_xml => parent_xml, :service_deployment => service_deployment }
  end
  
  # <related>
  if show_related
    render :partial => "service_deployments/api/related_links", :locals => { :parent_xml => parent_xml, :service_deployment => service_deployment }
  end
  
end
