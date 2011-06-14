# BioCatalogue: app/views/rest_resources/api/_rest_resource.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# Defaults:
is_root = false unless local_assigns.has_key?(:is_root)
show_core = true unless local_assigns.has_key?(:show_core)
show_rest_methods = true unless local_assigns.has_key?(:show_rest_methods)
show_ancestors = false unless local_assigns.has_key?(:show_ancestors)
show_related = false unless local_assigns.has_key?(:show_related)

# <restResource>
parent_xml.tag! "restResource",
                xlink_attributes(uri_for_object(rest_resource), :title => xlink_title(rest_resource)).merge(is_root ? xml_root_attributes : {}),
                :resourceName => display_name(rest_resource, false),
                :resourceType => "RestResource" do
  
  # Core elements
  if show_core
    render :partial => "rest_resources/api/core_elements", :locals => { :parent_xml => parent_xml, :rest_resource => rest_resource }
  end
  
  # <restMethods>
  if show_rest_methods
    render :partial => "rest_resources/api/rest_methods", :locals => { :parent_xml => parent_xml, :rest_resource => rest_resource }
  end
  
  # <ancestors>
  if show_ancestors
    render :partial => "rest_resources/api/ancestors", :locals => { :parent_xml => parent_xml, :rest_resource => rest_resource }
  end
  
  # <related>
  if show_related
    render :partial => "rest_resources/api/related_links", :locals => { :parent_xml => parent_xml, :rest_resource => rest_resource }
  end
  
end
