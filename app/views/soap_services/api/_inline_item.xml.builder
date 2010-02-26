# BioCatalogue: app/views/soap_services/api/_inline_item.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <soapService>
render :partial => "soap_services/api/soap_service", 
       :locals => { :parent_xml => parent_xml,
                    :soap_service => soap_service,
                    :show_deployments => false,
                    :show_operations => false,
                    :show_ancestors => false,
                    :show_related => false }