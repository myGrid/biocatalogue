# BioCatalogue: app/views/rest_resources/api/_inline_item.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <restResource>
render :partial => "rest_resources/api/rest_resource", 
       :locals => { :parent_xml => parent_xml,
                    :rest_resource => rest_resource,
                    :show_rest_methods => false,
                    :show_ancestors => false,
                    :show_related => false }