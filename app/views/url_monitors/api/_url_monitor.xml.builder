# BioCatalogue: app/views/url_monitors/api/_url_monitor.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <urlMonitor>
parent_xml.tag! "urlMonitor" do
  
  # <url>
  parent_xml.url BioCatalogue::Monitoring.pingable_url(url_monitor.url)
  
  # <resource>
  parent_xml.resource nil, 
    { :resourceType => url_monitor.parent_type },
    xlink_attributes(uri_for_object(url_monitor.parent), :title => xlink_title("The resource from which the URL to be monitored is obtained from"))
  
end
