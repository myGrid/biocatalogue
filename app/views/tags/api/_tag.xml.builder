# BioCatalogue: app/views/categories/api/_category.xml.builder
#
# Copyright (c) 2009-2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# Defaults:
is_root = false unless local_assigns.has_key?(:is_root)
show_core = true unless local_assigns.has_key?(:show_core)
show_related = false unless local_assigns.has_key?(:show_related)

# <tag>
parent_xml.tag! "tag", 
                xlink_attributes(uri_for_path(BioCatalogue::Tags.generate_tag_show_uri(tag_name)), :title => xlink_title("Tag - #{tag_name}")).merge(is_root ? xml_root_attributes : {}),
                :resourceName => tag_name,
                :resourceType => "Tag" do
  
  # Core elements
  if show_core
    render :partial => "tags/api/core_elements", :locals => { :parent_xml => parent_xml, :tag_name => tag_name, :tag_display_name => tag_display_name, :total_items_count => total_items_count }
  end
  
  # <related>
  if show_related
    render :partial => "tags/api/related_links", :locals => { :parent_xml => parent_xml, :tag_name => tag_name }
  end
  
end
