# BioCatalogue: app/views/rest_parameters/api/_rest_parameter.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# Defaults:
is_root = false unless local_assigns.has_key?(:is_root)
show_core = true unless local_assigns.has_key?(:show_core)
show_ancestors = false unless local_assigns.has_key?(:show_ancestors)
show_related = false unless local_assigns.has_key?(:show_related)

# <restParameter>
parent_xml.tag! "restParameter",
                xlink_attributes(uri_for_object(rest_parameter), :title => xlink_title(rest_parameter)).merge(is_root ? xml_root_attributes : {}),
                :resourceType => "RestParameter" do
  
  # Core elements
  if show_core
    render :partial => "rest_parameters/api/core_elements", :locals => { :parent_xml => parent_xml, :rest_parameter => rest_parameter }
  end
  
  # <ancestors>
  if show_ancestors
    render :partial => "rest_parameters/api/ancestors", :locals => { :parent_xml => parent_xml, :rest_parameter => rest_parameter }
  end
  
  # <related>
  if show_related
    render :partial => "rest_parameters/api/related_links", :locals => { :parent_xml => parent_xml, :rest_parameter => rest_parameter }
  end
  
end
