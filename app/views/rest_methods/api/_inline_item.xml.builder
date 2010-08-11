# BioCatalogue: app/views/rest_methods/api/_inline_item.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <restMethod>
render :partial => "rest_methods/api/rest_method", 
       :locals => { :parent_xml => parent_xml,
                    :rest_method => rest_method,
                    :show_inputs => false,
                    :show_outputs => false,
                    :show_ancestors => false,
                    :show_related => false }