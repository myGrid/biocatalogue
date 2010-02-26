# BioCatalogue: app/views/categories/api/_result_item.xml.builder
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <category>
render :partial => "categories/api/category", 
             :locals => { :parent_xml => parent_xml,
                          :category => category,
                          :show_narrower => false,
                          :show_broader => false,
                          :show_related => true }
