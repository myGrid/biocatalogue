# BioCatalogue: app/views/rest_services/api/_result_item.xml.builder
#
# Copyright (c) 2011, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <restService>
render :partial => "rest_services/api/rest_service", 
       :locals => { :parent_xml => parent_xml,
                    :rest_service => rest_service,
                    :show_deployments => @api_params[:include].include?("all") || @api_params[:include].include?("deployments"),
                    :show_rest_resources => @api_params[:include].include?("all") || @api_params[:include].include?("rest_resources"),
                    :show_rest_methods => @api_params[:include].include?("all") || @api_params[:include].include?("rest_methods"),
                    :show_ancestors => @api_params[:include].include?("all") || @api_params[:include].include?("ancestors"),
                    :show_related => true }
