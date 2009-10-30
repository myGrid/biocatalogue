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
parent_xml.related do
  
  # <summary>
  parent_xml.summary xlink_attributes(uri_for_object(service, :sub_path => "summary"), :title => xlink_title("Summary view of Service - #{display_name(service)}"))
  
end