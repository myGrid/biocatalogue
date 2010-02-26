# BioCatalogue: app/views/test_results/api/_test_result.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# Defaults:
is_root = false unless local_assigns.has_key?(:is_root)
show_core = true unless local_assigns.has_key?(:show_core)
show_ancestors = false unless local_assigns.has_key?(:show_ancestors)
show_related = false unless local_assigns.has_key?(:show_related)

# <testResult>
parent_xml.tag! "testResult",
                xlink_attributes(uri_for_object(test_result)).merge(is_root ? xml_root_attributes : {}),
                :resourceType => "TestResult" do
  
  # Core elements
  if show_core
    render :partial => "test_results/api/core_elements", :locals => { :parent_xml => parent_xml, :test_result => test_result }
  end
  
  # <ancestors>
  if show_ancestors
    render :partial => "test_results/api/ancestors", :locals => { :parent_xml => parent_xml, :test_result => test_result }
  end
  
  # <related>
  if show_related
    render :partial => "test_results/api/related_links", :locals => { :parent_xml => parent_xml, :test_result => test_result }
  end
  
end
