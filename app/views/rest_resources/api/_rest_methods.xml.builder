# BioCatalogue: app/views/rest_resources/api/_parameters.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details


# <methods>
parent_xml.tag! "methods",
                xlink_attributes(uri_for_object(rest_resource)),
                :resourceType => "RestResource" do
                  
  rest_resource.rest_methods.each do |rest_method|
    # <restMethod>
    render :partial => "rest_methods/api/inline_item", :locals => { :parent_xml => parent_xml, :rest_method => rest_method }
  end
  
end