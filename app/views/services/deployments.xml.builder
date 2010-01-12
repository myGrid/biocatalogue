# BioCatalogue: app/views/services/deployments.xml.builder
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <?xml>
xml.instruct! :xml

# <service>
xml.tag! "service", 
         xlink_attributes(uri_for_object(@service, :params => params)), 
         xml_root_attributes do
  
  render :partial => "services/api/core_elements", :locals => { :parent_xml => xml, :service => @service }
  
  # <deployments>
  render :partial => "services/api/deployments", :locals => { :parent_xml => xml, :service => @service }
  
  # <related>
  render :partial => "services/api/related_links_for_service", :locals => { :parent_xml => xml, :service => @service }
  
end