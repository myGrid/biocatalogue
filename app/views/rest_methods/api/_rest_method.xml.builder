# BioCatalogue: app/views/rest_methods/api/_rest_method.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# Defaults:
is_root = false unless local_assigns.has_key?(:is_root)
show_core = true unless local_assigns.has_key?(:show_core)
show_inputs = true unless local_assigns.has_key?(:show_inputs)
show_outputs = true unless local_assigns.has_key?(:show_outputs)
show_ancestors = false unless local_assigns.has_key?(:show_ancestors)
show_related = false unless local_assigns.has_key?(:show_related)

# <restMethod>
parent_xml.tag! "restMethod",
                xlink_attributes(uri_for_object(rest_method), :title => xlink_title(rest_method)).merge(is_root ? xml_root_attributes : {}),
                :resourceName => rest_method.endpoint_name,
                :resourceType => "RestMethod" do
  
  # Core elements
  if show_core
    render :partial => "rest_methods/api/core_elements", :locals => { :parent_xml => parent_xml, :rest_method => rest_method }
  end
  
  # <inputs>
  if show_inputs
    parent_xml.inputs xlink_attributes(uri_for_object(rest_method, :sub_path => "inputs")), :resourceType => "RestMethod" do |sub_node|
      render :partial => "rest_methods/api/inputs", :locals => { :parent_xml => sub_node, :rest_method => rest_method }
    end
  end
  
  # <outputs>
  if show_outputs
    parent_xml.outputs xlink_attributes(uri_for_object(rest_method, :sub_path => "outputs")), :resourceType => "RestMethod" do |sub_node|
      render :partial => "rest_methods/api/outputs", :locals => { :parent_xml => sub_node, :rest_method => rest_method }
    end
  end
  
  # <ancestors>
  if show_ancestors
    render :partial => "rest_methods/api/ancestors", :locals => { :parent_xml => parent_xml, :rest_method => rest_method }
  end
  
  # <related>
  if show_related
    render :partial => "rest_methods/api/related_links", :locals => { :parent_xml => parent_xml, :rest_method => rest_method }
  end
  
end
