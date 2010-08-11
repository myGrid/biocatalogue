# BioCatalogue: app/views/rest_services/rest_resources.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <?xml>
xml.instruct! :xml

# <restService>
render :partial => "rest_services/api/rest_service", 
       :locals => { :parent_xml => xml,
                    :rest_service => @rest_service,
                    :is_root => true,
                    :show_deployments => false,
                    :show_rest_resources => true,
                    :show_ancestors => false,
                    :show_related => true }
