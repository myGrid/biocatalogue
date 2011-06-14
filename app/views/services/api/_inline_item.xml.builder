# BioCatalogue: app/views/services/api/_inline_item.builder
#
# Copyright (c) 2009-2011, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <service>
render :partial => "services/api/service", 
       :locals => { :parent_xml => parent_xml,
                    :service => service,
                    :show_summary => false,
                    :show_deployments => false,
                    :show_variants => false,
                    :show_monitoring => true,
                    :show_related => false }