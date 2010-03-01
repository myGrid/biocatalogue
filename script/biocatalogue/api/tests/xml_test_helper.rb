# BioCatalogue: script/biocatalogue/api/tests/xml_test_helper.rb
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

require File.join(File.dirname(__FILE__), 'test_helper')

require 'open-uri'
require 'libxml'

module XmlTestHelper

  include TestHelper
  
  include LibXML
  
  SCHEMA_FILE_PATH = File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'public', '2009', 'xml', 'rest', 'schema-v1.xsd')
  
  def validate_endpoint_xml_output(endpoint_url)
    xml = open(endpoint_url, "Accept" => "application/xml", "User-Agent" => HTTP_USER_AGENT).read
    document = XML::Document.string(xml)
    schema = XML::Schema.new(SCHEMA_FILE_PATH)
    result = document.validate_schema(schema) do |message,flag|
      puts ""
      puts "#{(flag ? 'ERROR' : 'WARNING')}: #{message}"
      puts ""
    end
    return result
  end
  
end
