# BioCatalogue: app/views/categories/api/_category.xml.builder
#
# Copyright (c) 2009-2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# Defaults:
is_root = false unless local_assigns.has_key?(:is_root)
show_core = true unless local_assigns.has_key?(:show_core)
show_narrower = false unless local_assigns.has_key?(:show_narrower)
show_broader = false unless local_assigns.has_key?(:show_broader)
show_related = false unless local_assigns.has_key?(:show_related)

# <category>
parent_xml.tag! "category", 
                xlink_attributes(uri_for_object(category), :title => xlink_title(category)).merge(is_root ? xml_root_attributes : {}),
                :resourceType => "Category" do
  
  # Core elements
  if show_core
    render :partial => "categories/api/core_elements", :locals => { :parent_xml => parent_xml, :category => category }
  end
  
  # <broader>
  if show_broader
    parent_xml.broader do
      unless category.parent.nil?
      
        
        # <category>
        render :partial => "categories/api/category", 
               :locals => { :parent_xml => parent_xml,
                            :category => category.parent,
                            :show_narrower => false,
                            :show_broader => false,
                            :show_related => false }
      
      end
    end
  end
  
  # <narrower>
  if show_narrower
    parent_xml.narrower do
      category.children.each do |cat|
      
        # <category>
        render :partial => "categories/api/category", 
               :locals => { :parent_xml => parent_xml,
                            :category => cat,
                            :show_narrower => false,
                            :show_broader => false,
                            :show_related => false }
      end
    end
  end
  
  # <related>
  if show_related
    render :partial => "categories/api/related_links", :locals => { :parent_xml => parent_xml, :category => category }  
  end
  
end