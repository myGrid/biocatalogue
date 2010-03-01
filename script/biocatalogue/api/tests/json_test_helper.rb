# BioCatalogue: script/biocatalogue/api/tests/json_test_helper.rb
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

require File.join(File.dirname(__FILE__), 'test_helper')

require 'open-uri'
require 'json'

module JsonTestHelper

  include TestHelper
  
  def load_data_from_endpoint(endpoint_url)
    JSON.parse(open(endpoint_url, "Accept" => "application/json", "User-Agent" => HTTP_USER_AGENT).read)
  end
  
end
