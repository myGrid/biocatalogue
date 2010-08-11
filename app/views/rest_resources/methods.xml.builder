# BioCatalogue: app/views/rest_resources/methods.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <?xml>
xml.instruct! :xml

# <restResource>
render :partial => "rest_resources/api/rest_resource", 
       :locals => { :parent_xml => xml,
                    :is_root => true,
                    :show_rest_methods => true,
                    :show_ancestors => false,
                    :show_related => true }
