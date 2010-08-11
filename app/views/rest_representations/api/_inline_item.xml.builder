# BioCatalogue: app/views/rest_representations/api/_inline_item.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <restParameter>
render :partial => "rest_representations/api/rest_representation", 
       :locals => { :parent_xml => parent_xml,
                    :rest_representation => rest_representation,
                    :show_ancestors => false,
                    :show_related => false }