# BioCatalogue: app/views/saved_searches/api/_saved_search.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# Defaults:
is_root = false unless local_assigns.has_key?(:is_root)
show_core = true unless local_assigns.has_key?(:show_core)
show_scopes = true unless local_assigns.has_key?(:show_scopes)
show_user = true unless local_assigns.has_key?(:show_user)

# <savedSearch>
parent_xml.tag! "savedSearch",
                xlink_attributes(uri_for_object(saved_search), :title => xlink_title(saved_search)).merge(is_root ? xml_root_attributes : {}),
                :resourceType => "SavedSearch" do
  
  # Core elements
  if show_core
    render :partial => "saved_searches/api/core_elements", :locals => { :parent_xml => parent_xml, :saved_search => saved_search, :show_scopes => show_scopes, :show_user => show_user }
  end
  
end
