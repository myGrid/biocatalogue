# BioCatalogue: app/views/categories/show.xml.builder
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <?xml>
xml.instruct! :xml

# <category>
render :partial => "categories/api/category", 
       :locals => { :parent_xml => xml,
                    :category => @category,
                    :is_root => true,
                    :show_narrower => true,
                    :show_broader => true,
                    :show_related => true }
