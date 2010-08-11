# BioCatalogue: app/views/rest_parameters/api/_inline_item.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <restParameter>
render :partial => "rest_parameters/api/rest_parameter", 
       :locals => { :parent_xml => parent_xml,
                    :rest_parameter => rest_parameter,
                    :show_ancestors => false,
                    :show_related => false }