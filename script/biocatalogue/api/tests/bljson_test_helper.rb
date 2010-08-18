# BioCatalogue: script/biocatalogue/api/tests/bljson_test_helper.rb
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

require File.join(File.dirname(__FILE__), 'test_helper')

require 'open-uri'
require 'json'

module BljsonTestHelper

  include TestHelper
  
  def load_data_from_endpoint(endpoint_url)
    JSON.parse(open(endpoint_url, "Accept" => "application/json", "User-Agent" => HTTP_USER_AGENT).read)
  end
  
  def validate_data_from_path(path)
    data = load_data_from_endpoint(make_url(path))
    assert data.is_a?(Hash), data_incorrect_class_msg(data, path)
    assert !data.empty?, data_empty_msg(path, Hash)
    return data
  end
  
  # ========================================
  
  def element_nil_msg(element, path)
    "The element '#{element}' at path '#{path}' was found to be nil."
  end
  
  def data_incorrect_class_msg(data, path)
    "The result of path '#{path}' is not of the correct data type. Found #{data.class.name}."
  end
  
  def data_empty_msg(path, required_class)
    "The path '#{path}' yielded an empty #{required_class.name}."
  end
  
  # ========================================

  def validate_index_from_path(path, allow_empty=false)
    data = validate_data_from_path(path)
    resource_name = data.keys.first
    
    assert !data[resource_name].nil?, element_nil_msg(resource_name, path)
  end
  
  # ========================================
    
end
