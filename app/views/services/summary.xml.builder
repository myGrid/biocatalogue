# BioCatalogue: app/views/services/summary.xml.builder
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <?xml>
xml.instruct! :xml

# <service>
render :partial => "services/api/service", 
       :locals => { :parent_xml => xml,
                    :service => @service,
                    :is_root => true,
                    :show_summary => true,
                    :show_deployments => false,
                    :show_versions => false,
                    :show_monitoring => false,
                    :show_related => true }
