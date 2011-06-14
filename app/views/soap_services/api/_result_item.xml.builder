# BioCatalogue: app/views/soap_services/api/_result_item.xml.builder
#
# Copyright (c) 2011, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <soapService>
render :partial => "soap_services/api/soap_service", 
       :locals => { :parent_xml => parent_xml,
                    :soap_service => soap_service,
                    :show_deployments => @api_params[:include].include?("all") || @api_params[:include].include?("deployments"),
                    :show_operations => @api_params[:include].include?("all") || @api_params[:include].include?("operations"),
                    :show_ancestors => @api_params[:include].include?("all") || @api_params[:include].include?("ancestors"),
                    :show_related => true }
