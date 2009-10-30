# BioCatalogue: app/views/services/api/_result_item.xml.builder
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

render :partial => "services/api/core_elements", :locals => { :parent_xml => parent_xml, :service => service }
        
# <summary>
if @api_params[:include_elements].include?("summary")
  render :partial => "services/api/summary", :locals => { :parent_xml => parent_xml, :service => service }
end

# <related>
render :partial => "services/api/related_links_for_service", :locals => { :parent_xml => parent_xml, :service => service }