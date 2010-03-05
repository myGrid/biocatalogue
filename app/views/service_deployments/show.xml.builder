# BioCatalogue: app/views/service_deployments/show.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <?xml>
xml.instruct! :xml

# <serviceDeployment>
render :partial => "service_deployments/api/service_deployment", 
       :locals => { :parent_xml => xml,
                    :service_deployment => @service_deployment,
                    :is_root => true,
                    :show_provided_variant => true,
                    :show_ancestors => true,
                    :show_related => true }
