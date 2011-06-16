# BioCatalogue: app/views/soap_inputs/api/_soap_input.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# Defaults:
is_root = false unless local_assigns.has_key?(:is_root)
show_core = true unless local_assigns.has_key?(:show_core)
show_ancestors = false unless local_assigns.has_key?(:show_ancestors)
show_related = false unless local_assigns.has_key?(:show_related)

# <soapInput>
parent_xml.tag! "soapInput",
                xlink_attributes(uri_for_object(soap_input), :title => xlink_title(soap_input)).merge(is_root ? xml_root_attributes : {}),
                :resourceName => display_name(soap_input, false),
                :resourceType => "SoapInput" do
  
  # Core elements
  if show_core
    render :partial => "soap_inputs/api/core_elements", :locals => { :parent_xml => parent_xml, :soap_input => soap_input }
  end
  
  # <ancestors>
  if show_ancestors
    render :partial => "soap_inputs/api/ancestors", :locals => { :parent_xml => parent_xml, :soap_input => soap_input }
  end
  
  # <related>
  if show_related
    render :partial => "soap_inputs/api/related_links", :locals => { :parent_xml => parent_xml, :soap_input => soap_input }
  end
  
end
