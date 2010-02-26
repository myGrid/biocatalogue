# BioCatalogue: app/views/users/api/_inline_item.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <serviceProvider>
render :partial => "users/api/user", 
       :locals => { :parent_xml => parent_xml,
                    :user => user,
                    :show_related => false }