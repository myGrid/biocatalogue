# BioCatalogue: app/views/service_providers/api/_result_item.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <serviceProvider>
render :partial => "service_providers/api/service_provider", 
       :locals => { :parent_xml => parent_xml,
                    :service_provider => service_provider,
                    :show_related => true }