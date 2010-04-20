# BioCatalogue: app/views/users/api/_user.xml.builder
#
# Copyright (c) 2009-2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# Defaults:
is_root = false unless local_assigns.has_key?(:is_root)
show_core = true unless local_assigns.has_key?(:show_core)
show_related = false unless local_assigns.has_key?(:show_related)

if user.activated?

  # <user>
  parent_xml.tag! "user",
                  xlink_attributes(uri_for_object(user), :title => xlink_title(user)).merge(is_root ? xml_root_attributes : {}),
                  :resourceType => "User" do
    
    # Core elements
    if show_core
      render :partial => "users/api/core_elements", :locals => { :parent_xml => parent_xml, :user => user }
    end
    
    # <related>
    if show_related
      render :partial => "users/api/related_links", :locals => { :parent_xml => parent_xml, :user => user }
    end
    
  end

end
