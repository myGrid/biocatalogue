# BioCatalogue: app/views/users/show.xml.builder
#
# Copyright (c) 2009-2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <?xml>
xml.instruct! :xml

# <user>
render :partial => "users/api/user", 
       :locals => { :parent_xml => xml,
                    :user => @user,
                    :show_saved_searches => true,
                    :is_root => true,
                    :show_related => true }
