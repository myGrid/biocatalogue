# BioCatalogue: app/views/categories/api/_result_item.xml.builder
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

parent_xml.category xlink_attributes(uri_for_object(category), :title => xlink_title(category)) do
  parent_xml.name display_name(category)
  
  # <related>
  render :partial => "categories/api/related_links_for_category", :locals => { :parent_xml => parent_xml, :category => category }
end