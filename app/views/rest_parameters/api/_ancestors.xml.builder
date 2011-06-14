# BioCatalogue: app/views/rest_parameters/api/_ancestors.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <ancestors>
parent_xml.ancestors do
  
  # <service>
  render :partial => "services/api/inline_item", :locals => { :parent_xml => parent_xml, :service => @rest_methods[0].associated_service }
  
  # <restService>
  render :partial => "rest_services/api/inline_item", :locals => { :parent_xml => parent_xml, :rest_service => @rest_methods[0].rest_service }

  # <restResources>
  parent_xml.restResources do |xml_node|
    @rest_methods.each do |meth|
      # <restResource>
      render :partial => "rest_resources/api/inline_item", :locals => { :parent_xml => parent_xml, :rest_resource => meth.rest_resource }
    end
  end

  # <restMethods>
  parent_xml.restMethods do |xml_node|
    @rest_methods.each do |meth|
      # <restMethod>
      render :partial => "rest_methods/api/inline_item", :locals => { :parent_xml => parent_xml, :rest_method => meth }
    end
  end
    
end