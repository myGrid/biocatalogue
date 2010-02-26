# BioCatalogue: app/views/tags/show.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <?xml>
xml.instruct! :xml

# <tag>
render :partial => "tags/api/tag", 
             :locals => { :parent_xml => xml,
                          :is_root => true,
                          :tag_name => @tag_name,
                          :tag_display_name => @tag_display_name,
                          :total_items_count => @total_items_count,
                          :show_related => true }