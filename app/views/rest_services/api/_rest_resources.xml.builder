# BioCatalogue: app/views/rest_services/api/_rest_resources.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <resources>
parent_xml.tag! "resources",
                xlink_attributes(uri_for_object(rest_service, :sub_path => "resources")),
                :resourceType => "RestService" do
                  
  rest_service.rest_resources.each do |rest_resource|
    # <restResource>
    render :partial => "rest_resources/api/inline_item", :locals => { :parent_xml => parent_xml, :rest_resource => rest_resource }
  end
  
end