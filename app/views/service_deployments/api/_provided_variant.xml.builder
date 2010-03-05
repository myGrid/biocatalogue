# BioCatalogue: app/views/service_deployments/api/_provided_variant.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <providedVariant>
parent_xml.providedVariant do
  
  s = service_deployment.service_version.service_versionified
  render :partial => "#{s.class.name.underscore.pluralize}/api/inline_item", :locals => { :parent_xml => parent_xml, s.class.name.underscore.to_sym => s }
  
end