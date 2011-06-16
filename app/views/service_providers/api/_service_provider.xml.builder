# BioCatalogue: app/views/service_providers/api/_service_provider.xml.builder
#
# Copyright (c) 2009-2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# Defaults:
is_root = false unless local_assigns.has_key?(:is_root)
show_core = true unless local_assigns.has_key?(:show_core)
show_related = false unless local_assigns.has_key?(:show_related)
show_hostnames = false unless local_assigns.has_key?(:show_hostnames)

# <serviceProvider>
parent_xml.tag! "serviceProvider",
                xlink_attributes(uri_for_object(service_provider), :title => xlink_title(service_provider)).merge(is_root ? xml_root_attributes : {}),
                :resourceName => display_name(service_provider, false),
                :resourceType => "ServiceProvider" do
  
  # Core elements
  if show_core
    render :partial => "service_providers/api/core_elements", :locals => { :parent_xml => parent_xml, :service_provider => service_provider }
  end
  
  # <hostnames>
  if show_hostnames
    render :partial => "service_providers/api/hostnames", :locals => { :parent_xml => parent_xml, :service_provider => service_provider }
  end
  
  # <related>
  if show_related
    render :partial => "service_providers/api/related_links", :locals => { :parent_xml => parent_xml, :service_provider => service_provider }
  end
  
end
