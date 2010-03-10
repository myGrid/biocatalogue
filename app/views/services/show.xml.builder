# BioCatalogue: app/views/services/show.xml.builder
#
# Copyright (c) 2009-2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <?xml>
xml.instruct! :xml

# <service>
render :partial => "services/api/service", 
       :locals => { :parent_xml => xml,
                    :service => @service,
                    :is_root => true,
                    :show_summary => @api_params[:include].include?("summary"),
                    :show_deployments => true,
                    :show_variants => true,
                    :show_monitoring => @api_params[:include].include?("monitoring"),
                    :show_related => true }
