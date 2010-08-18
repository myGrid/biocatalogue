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
    JSON.parse(open(endpoint_url, "Accept" => "application/biocat-lean+json", "User-Agent" => HTTP_USER_AGENT).read)
  end
  
  def load_data_from_main_json_endpoint(endpoint_url)
    JSON.parse(open(endpoint_url, "Accept" => "application/json", "User-Agent" => HTTP_USER_AGENT).read)
  end
  
  def validate_data_from_path(path, allow_empty=false)
    data = load_data_from_endpoint(make_url(path))
    assert data.is_a?(Hash), data_incorrect_class_msg(data, path)
    assert !data.empty?, data_empty_msg(path, Hash) unless allow_empty
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
    data = validate_data_from_path(path, allow_empty)
    resource_name = data.keys.first
    
    assert !data[resource_name].nil?, element_nil_msg(resource_name, path)
    
    # Get the main JSON API version and compare the numbers
    # (this assumes the JSON API is working as expected!)
    data2 = load_data_from_main_json_endpoint(make_url(path))
    
    assert data[resource_name].length == data2[resource_name]["total"], "Different number of results found between the bljson and json endpoints"
  end
  
  # ========================================
    
end
