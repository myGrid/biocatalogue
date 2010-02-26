# BioCatalogue: app/views/soap_outputs/api/_soap_output.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# Defaults:
is_root = false unless local_assigns.has_key?(:is_root)
show_core = true unless local_assigns.has_key?(:show_core)
show_ancestors = false unless local_assigns.has_key?(:show_ancestors)
show_related = false unless local_assigns.has_key?(:show_related)

# <soapOutput>
parent_xml.tag! "soapOutput",
                xlink_attributes(uri_for_object(soap_output), :title => xlink_title(soap_output)).merge(is_root ? xml_root_attributes : {}),
                :resourceType => "SoapOutput" do
  
  # Core elements
  if show_core
    render :partial => "soap_outputs/api/core_elements", :locals => { :parent_xml => parent_xml, :soap_output => soap_output }
  end
  
  # <ancestors>
  if show_ancestors
    render :partial => "soap_outputs/api/ancestors", :locals => { :parent_xml => parent_xml, :soap_output => soap_output }
  end
  
  # <related>
  if show_related
    render :partial => "soap_outputs/api/related_links", :locals => { :parent_xml => parent_xml, :soap_output => soap_output }
  end
  
end
