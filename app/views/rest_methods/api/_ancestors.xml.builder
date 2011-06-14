# BioCatalogue: app/views/rest_methods/api/_ancestors.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <ancestors>
parent_xml.ancestors do
  
  # <service>
  render :partial => "services/api/inline_item", :locals => { :parent_xml => parent_xml, :service => rest_method.associated_service }
  
  # <restService>
  render :partial => "rest_services/api/inline_item", :locals => { :parent_xml => parent_xml, :rest_service => rest_method.rest_resource.rest_service }

  # <restResource>
  render :partial => "rest_resources/api/inline_item", :locals => { :parent_xml => parent_xml, :rest_resource => rest_method.rest_resource }
    
end