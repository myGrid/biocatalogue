# BioCatalogue: app/views/registries/api/_registry.xml.builder
#
# Copyright (c) 2009-2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# Defaults:
is_root = false unless local_assigns.has_key?(:is_root)
show_core = true unless local_assigns.has_key?(:show_core)
show_related = false unless local_assigns.has_key?(:show_related)

# <registry>
parent_xml.tag! "registry",
                xlink_attributes(uri_for_object(registry), :title => xlink_title(registry)).merge(is_root ? xml_root_attributes : {}),
                :resourceName => display_name(registry, false),
                :resourceType => "Registry" do
  
  # Core elements
  if show_core
    render :partial => "registries/api/core_elements", :locals => { :parent_xml => parent_xml, :registry => registry }
  end
  
  # <related>
  if show_related
    render :partial => "registries/api/related_links", :locals => { :parent_xml => parent_xml, :registry => registry }
  end
  
end
