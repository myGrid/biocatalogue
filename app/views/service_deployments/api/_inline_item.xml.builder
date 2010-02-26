# BioCatalogue: app/views/service_deployments/api/_inline_item.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <serviceDeployment>
render :partial => "service_deployments/api/service_deployment", 
       :locals => { :parent_xml => parent_xml,
                    :service_deployment => service_deployment,
                    :show_hosted_version => false,
                    :show_ancestors => false,
                    :show_related => false }