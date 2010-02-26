# BioCatalogue: app/views/registries/api/_result_item.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <serviceProvider>
render :partial => "registries/api/registry", 
       :locals => { :parent_xml => parent_xml,
                    :registry => registry,
                    :show_related => true }