# BioCatalogue: app/views/test_scripts/api/_test_script.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <testScript>
parent_xml.tag! "testScript" do
  
  # <name>
  parent_xml.name test_script.name
  
  # <dc:description>
  dc_xml_tag parent_xml, :description, test_script.description
  
  # <contentType>
  parent_xml.contentType test_script.content_type
  
  # <programmingLanguage>
  parent_xml.programmingLanguage test_script.prog_language
  
  # <executableFilename>
  parent_xml.executableFilename test_script.exec_name
  
  # <download>
  parent_xml.download xlink_attributes(download_test_script_url(test_script), :title => "The download link to the test script file/package")
  
  # <submitter>
  parent_xml.submitter xlink_attributes(uri_for_object(test_script.submitter), :title => xlink_title(test_script.submitter)), 
                       :resourceType => test_script.submitter_type,
                       :resourceName => display_name(test_script.submitter, false)
  
  # <dcterms:created>
  dcterms_xml_tag parent_xml, :created, test_script.created_at
  
  # <activatedAt>
  if test_script.activated_at
    parent_xml.activatedAt test_script.activated_at.iso8601
  else
    parent_xml.activatedAt nil, "xsi:nil" => "true"
  end
  
end
