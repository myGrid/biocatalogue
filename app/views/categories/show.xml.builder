# BioCatalogue: app/views/categories/show.xml.builder
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <?xml>
xml.instruct! :xml

xml.tag! "category", 
         xlink_attributes(uri_for_object(@category, :params => params)), 
         xml_root_attributes do
  
  # <name>
  xml.name display_name(@category)
  
  # <broader> *
  unless @category.parent.nil?
    xml.broader do
      # <category>
      render :partial => "categories/api/result_item", :locals => { :parent_xml => xml, :category => @category.parent }
    end
  end
  
  # <narrower> *
  @category.children.each do |cat|
    xml.narrower do
      # <category>
      render :partial => "categories/api/result_item", :locals => { :parent_xml => xml, :category => cat }
    end
  end
  
  # <related>
  render :partial => "categories/api/related_links_for_category", :locals => { :parent_xml => xml, :category => @category }
     
end