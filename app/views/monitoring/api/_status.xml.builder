# BioCatalogue: app/views/monitoring/api/_status.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

element_name = "status" unless local_assigns.has_key?(:element_name)

parent_xml.tag! element_name do
      
  # <label>
  parent_xml.label status.label
  
  # <message>
  parent_xml.message status.message
  
  # <symbol>
  parent_xml.symbol xlink_attributes(uri_for_path(image_path(status.symbol_filename)), :title => "Large status symbol icon for this monitoring status")
  
  # <smallSymbol>
  parent_xml.smallSymbol xlink_attributes(uri_for_path(image_path(status.small_symbol_filename)), :title => "Small status symbol icon for this monitoring status")
  
  # <lastChecked>
  if status.last_checked
    parent_xml.lastChecked status.last_checked.iso8601
  else
    parent_xml.lastChecked "", "xsi:nil" => "true"
  end
  
end