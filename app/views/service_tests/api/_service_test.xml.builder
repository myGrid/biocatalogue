# BioCatalogue: app/views/service_tests/api/_service_test.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# Defaults:
is_root = false unless local_assigns.has_key?(:is_root)
show_core = true unless local_assigns.has_key?(:show_core)
show_latest_status = false unless local_assigns.has_key?(:show_latest_status)
show_ancestors = false unless local_assigns.has_key?(:show_ancestors)
show_related = false unless local_assigns.has_key?(:show_related)

# <serviceTest>
parent_xml.tag! "serviceTest",
                xlink_attributes(uri_for_object(service_test)).merge(is_root ? xml_root_attributes : {}),
                :resourceType => "ServiceTest" do
  
  # Core elements
  if show_core
    render :partial => "service_tests/api/core_elements", :locals => { :parent_xml => parent_xml, :service_test => service_test }
  end
  
  # <latestStatus>
  if show_latest_status
    render :partial => "monitoring/api/status",
       :locals => { :parent_xml => parent_xml, 
                    :element_name => "latestStatus", 
                    :status => service_test.latest_status }
  end
  
  # <ancestors>
  if show_ancestors
    render :partial => "service_tests/api/ancestors", :locals => { :parent_xml => parent_xml, :service_test => service_test }
  end
  
  # <related>
  if show_related
    render :partial => "service_tests/api/related_links", :locals => { :parent_xml => parent_xml, :service_test => service_test }
  end
  
end
