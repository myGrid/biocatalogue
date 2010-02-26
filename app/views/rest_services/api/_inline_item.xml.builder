# BioCatalogue: app/views/rest_services/api/_inline_item.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <restService>
render :partial => "rest_services/api/rest_service", 
       :locals => { :parent_xml => parent_xml,
                    :rest_service => rest_service,
                    :show_deployments => false,
                    :show_ancestors => false,
                    :show_related => false }