# BioCatalogue: app/views/soap_operations/api/_soap_operation.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# Defaults:
is_root = false unless local_assigns.has_key?(:is_root)
show_core = true unless local_assigns.has_key?(:show_core)
show_inputs = false unless local_assigns.has_key?(:show_inputs)
show_outputs = false unless local_assigns.has_key?(:show_outputs)
show_ancestors = false unless local_assigns.has_key?(:show_ancestors)
show_related = false unless local_assigns.has_key?(:show_related)

# <soapOperation>
parent_xml.tag! "soapOperation",
                xlink_attributes(uri_for_object(soap_operation), :title => xlink_title(soap_operation)).merge(is_root ? xml_root_attributes : {}),
                :resourceName => display_name(soap_operation, false),
                :resourceType => "SoapOperation" do
  
  # Core elements
  if show_core
    render :partial => "soap_operations/api/core_elements", :locals => { :parent_xml => parent_xml, :soap_operation => soap_operation }
  end
  
  # <inputs>
  if show_inputs
    render :partial => "soap_operations/api/inputs", :locals => { :parent_xml => parent_xml, :soap_operation => soap_operation }
  end
  
  # <outputs>
  if show_outputs
    render :partial => "soap_operations/api/outputs", :locals => { :parent_xml => parent_xml, :soap_operation => soap_operation }
  end
  
  # <ancestors>
  if show_ancestors
    render :partial => "soap_operations/api/ancestors", :locals => { :parent_xml => parent_xml, :soap_operation => soap_operation }
  end
  
  # <related>
  if show_related
    render :partial => "soap_operations/api/related_links", :locals => { :parent_xml => parent_xml, :soap_operation => soap_operation }
  end
  
end
