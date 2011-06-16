# BioCatalogue: app/views/agents/api/_agent.xml.builder
#
# Copyright (c) 2009-2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# Defaults:
is_root = false unless local_assigns.has_key?(:is_root)
show_core = true unless local_assigns.has_key?(:show_core)
show_related = false unless local_assigns.has_key?(:show_related)

# <agent>
parent_xml.tag! "agent",
                xlink_attributes(uri_for_object(agent), :title => xlink_title(agent)).merge(is_root ? xml_root_attributes : {}),
                :resourceName => display_name(agent, false),
                :resourceType => "Agent" do
  
  # Core elements
  if show_core
    render :partial => "agents/api/core_elements", :locals => { :parent_xml => parent_xml, :agent => agent }
  end
  
  # <related>
  if show_related
    render :partial => "agents/api/related_links", :locals => { :parent_xml => parent_xml, :agent => agent }
  end
  
end
