# BioCatalogue: script/biocatalogue/api/tests/bljson_tests.rb
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# Tests the custom BioCatalogue "lean" JSON API outputs.
# NOTE: this relies on their being a large dataset to test against (ie: lots of data in the db!)

require 'test/unit'
require File.join(File.dirname(__FILE__), 'bljson_test_helper')

class JsonTests < Test::Unit::TestCase
  
  include BljsonTestHelper

  def setup
  end
  
  # --------------------
  
  # /rest_methods
  def test_rest_methods
    validate_index_from_path("/rest_methods")
    validate_index_from_path("/rest_methods?sort_by=name")
    validate_index_from_path("/rest_methods?sort_by=name&sort_order=desc")
    validate_index_from_path("/rest_methods?sort_by=name&sort_order=asc")
    validate_index_from_path("/rest_methods?q=database", true)    
  end

  # /services
  def test_services
    validate_index_from_path("/services")
    validate_index_from_path("/services?t=[SOAP]")
    validate_index_from_path("/services?t=[SOAP]&p=[1],[3],[5]")
    validate_index_from_path("/services?t=[SOAP]&p=[1]&c=[United+Kingdom]")
    validate_index_from_path("/services?t=[SOAP]&p=[1]&c=[United+Kingdom]&q=blast", true)
    validate_index_from_path("/services?sort_by=created&sort_order=asc")

  end

  # /service_providers
  def test_service_providers
    validate_index_from_path("/service_providers")
    validate_index_from_path("/service_providers?sort_by=created&sort_order=asc")
    validate_index_from_path("/service_providers?sort_by=name")
    validate_index_from_path("/service_providers?sort_by=name&sort_order=desc")
    validate_index_from_path("/service_providers?sort_by=name&sort_order=asc")
    validate_index_from_path("/service_providers?q=ddbj", true)
    validate_index_from_path("/service_providers?c=[japan]")
    validate_index_from_path("/service_providers?c=[japan]&q=ddbj", true)
  end
  
  # /soap_operations
  def test_soap_operations
    validate_index_from_path("/soap_operations")
    validate_index_from_path("/soap_operations?sort_by=created&sort_order=asc")
    validate_index_from_path("/soap_operations?tag=[blast]")
    validate_index_from_path("/soap_operations?tag=[blast],[predicting]")
    validate_index_from_path("/soap_operations?tag_ins=[blast],[predicting]&tag_outs=[blast_report]", true)
    validate_index_from_path("/soap_operations?tag=[blast]&q=blast")
  end

  # /users
  def test_users
    validate_index_from_path("/users")
    validate_index_from_path("/users?sort_by=activated&sort_order=asc")
    validate_index_from_path("/users?sort_by=name")
    validate_index_from_path("/users?sort_by=name&sort_order=desc")
    validate_index_from_path("/users?sort_by=name&sort_order=asc")
    validate_index_from_path("/users?q=franck", true)
    validate_index_from_path("/users?c=[japan]")
    validate_index_from_path("/users?c=[japan]&q=franck", true)
  end

  # --------------------
  
  def teardown
  end

end

