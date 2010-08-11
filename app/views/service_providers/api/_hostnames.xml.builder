# BioCatalogue: app/views/service_providers/api/_hostnames.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <hostnames>
parent_xml.tag! "hostnames" do
  
  service_provider.service_provider_hostnames.each do |hostname|
    # <hostname>
    parent_xml.hostname display_name(hostname, false)
  end
  
end