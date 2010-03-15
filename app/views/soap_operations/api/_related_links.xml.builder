# BioCatalogue: app/views/soap_operations/api/_related_links.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <related>
parent_xml.related do
  
  # <inputs>
  parent_xml.inputs xlink_attributes(uri_for_object(soap_operation, :sub_path => "inputs"), :title => xlink_title("All SOAP Inputs for this SOAP Operation - #{display_name(soap_operation, false)}")),
                    :resourceType => "SoapOperation"
  
  # <outputs>
  parent_xml.outputs xlink_attributes(uri_for_object(soap_operation, :sub_path => "outputs"), :title => xlink_title("All SOAP outputs for this SOAP Operation - #{display_name(soap_operation, false)}")),
                     :resourceType => "SoapOperation"
  
  # <annotations>
  parent_xml.annotations xlink_attributes(uri_for_object(soap_operation, :sub_path => "annotations"), :title => xlink_title("All annotations on this SOAP Operation - #{display_name(soap_operation, false)}")),
                         :resourceType => "Annotations"
  
  # <annotationsOnAll>
  parent_xml.annotationsOnAll xlink_attributes(uri_for_object(soap_operation, :sub_path => "annotations", :params => { :also => "inputs,outputs" }), :title => xlink_title("All annotations on ALL parts of this SOAP Operation - #{display_name(soap_operation, false)} - i.e.: on all the inputs and outputs")),
                         :resourceType => "Annotations"
end