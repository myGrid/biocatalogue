# BioCatalogue: app/views/rest_representations/api/_ancestors.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <ancestors>
parent_xml.ancestors do
  
  # <service>
  service = @rest_methods[0].associated_service
  parent_xml.service nil, 
    { :resourceName => display_name(service, false), :resourceType => "Service" },
    xlink_attributes(uri_for_object(service), :title => xlink_title("The parent Service that this REST Representation - #{display_name(rest_representation, false)} - belongs to"))

  # <restService>
  parent_xml.restService nil, 
    { :resourceName => display_name(@rest_methods[0].rest_service, false), :resourceType => "RestService" },
    xlink_attributes(uri_for_object(@rest_methods[0].rest_service), :title => xlink_title("The parent REST Service that this REST Representation - #{display_name(rest_representation, false)} - belongs to"))

  # <restResources>
  parent_xml.restResources do |xml_node|
    @rest_methods.each do |meth|
      # <restResource>
        xml_node.restResource nil, 
          { :resourceName => meth.rest_resource.path, :resourceType => "RestResource" },
          xlink_attributes(uri_for_object(meth.rest_resource), :title => xlink_title("The parent REST Resource that this REST Representation - #{display_name(rest_representation, false)} - belongs to"))
    end
  end

  # <restMethods>
  parent_xml.restMethods do |xml_node|
    @rest_methods.each do |meth|
      # <restMethod>
        xml_node.restMethod nil, 
          { :resourceName => meth.display_endpoint, :resourceType => "RestMethod" },
          xlink_attributes(uri_for_object(meth), :title => xlink_title("The parent REST Method that this REST Representation - #{display_name(rest_representation, false)} - belongs to"))
    end
  end
    
end