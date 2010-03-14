# BioCatalogue: script/biocatalogue/api/tests/xml_schema_validations.rb
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# Tests the output of various endpoints of the XML REST API against the XSD.
# NOTE: this relies on their being a large dataset to test against (ie: lots of data in the db!)

require 'test/unit'
require File.join(File.dirname(__FILE__), 'xml_test_helper')

class XmlSchemaValidations < Test::Unit::TestCase
  
  include XmlTestHelper

  def setup
  end

  def test_root
    assert validate_endpoint_xml_output(make_url("/"))
  end
  
  def test_search
    assert validate_endpoint_xml_output(make_url("/search?q=ebi"))
    assert validate_endpoint_xml_output(make_url("/search?q=ebi&page=2"))
    assert validate_endpoint_xml_output(make_url("/search?q=ebi&page=3"))
    assert validate_endpoint_xml_output(make_url("/search?q=ebi&page=4"))
    assert validate_endpoint_xml_output(make_url("/search?q=ebi&page=5"))
    assert validate_endpoint_xml_output(make_url("/search?q=ebi&scope=services"))
    assert validate_endpoint_xml_output(make_url("/search?q=ebi&scope=services&page=2"))
    assert validate_endpoint_xml_output(make_url("/search?q=ebi&scope=service_providers"))
    assert validate_endpoint_xml_output(make_url("/search?q=ebi&scope=services,service_providers"))
    assert validate_endpoint_xml_output(make_url("/search?q=ebi&scope=services&include=summary"))
    assert validate_endpoint_xml_output(make_url("/search?q=ebi&scope=services&include=summary,related"))
    
    assert validate_endpoint_xml_output(make_url("/search?q=blast"))
    assert validate_endpoint_xml_output(make_url("/search?q=blast&page=2"))
    assert validate_endpoint_xml_output(make_url("/search?q=blast&scope=soap_operations"))
    assert validate_endpoint_xml_output(make_url("/search?q=blast&scope=soap_operations&include=inputs,ancestors"))
    assert validate_endpoint_xml_output(make_url("/search?q=blast&scope=soap_operations&include=inputs,ancestors&page=2"))
  end
    
  def test_services
    assert validate_endpoint_xml_output(make_url("/services"))
    assert validate_endpoint_xml_output(make_url("/services?page=2"))
    assert validate_endpoint_xml_output(make_url("/services?per_page=5"))
    assert validate_endpoint_xml_output(make_url("/services?per_page=5&page=3"))
    assert validate_endpoint_xml_output(make_url("/services?t=[SOAP]"))
    assert validate_endpoint_xml_output(make_url("/services?t=[SOAP]&p=[1]"))
    assert validate_endpoint_xml_output(make_url("/services?t=[SOAP]&p=[1],[3],[5]"))
    assert validate_endpoint_xml_output(make_url("/services?t=[SOAP]&p=[1]&c=[United+Kingdom]"))
    assert validate_endpoint_xml_output(make_url("/services?t=[SOAP]&per_page=5&page=3"))
    assert validate_endpoint_xml_output(make_url("/services?include=summary"))
    assert validate_endpoint_xml_output(make_url("/services?include=summary&page=2&per_page=20"))
    assert validate_endpoint_xml_output(make_url("/services?sort_by=created&sort_order=asc"))
    assert validate_endpoint_xml_output(make_url("/services?sort_by=created&sort_order=asc&page=3"))
  end
  
  def test_services_filters
    assert validate_endpoint_xml_output(make_url("/services/filters"))
  end
  
  def test_service
    assert config["service_ids"].length > 0, "No service_ids found in config.yml"
    config["service_ids"].each do |id|
      assert validate_endpoint_xml_output(make_url("/services/#{id}"))
      assert validate_endpoint_xml_output(make_url("/services/#{id}?include=summary"))
      assert validate_endpoint_xml_output(make_url("/services/#{id}?include=monitoring"))
      assert validate_endpoint_xml_output(make_url("/services/#{id}/summary"))
      assert validate_endpoint_xml_output(make_url("/services/#{id}/deployments"))
      assert validate_endpoint_xml_output(make_url("/services/#{id}/variants"))
      assert validate_endpoint_xml_output(make_url("/services/#{id}/annotations"))
      assert validate_endpoint_xml_output(make_url("/services/#{id}/monitoring"))
    end
  end
  
  def test_service_deployment
    assert config["service_deployment_ids"].length > 0, "No service_deployment_ids found in config.yml"
    config["service_deployment_ids"].each do |id|
      assert validate_endpoint_xml_output(make_url("/service_deployments/#{id}"))
      assert validate_endpoint_xml_output(make_url("/service_deployments/#{id}/annotations"))
    end
  end
  
  def test_soap_service
    assert config["soap_service_ids"].length > 0, "No soap_service_ids found in config.yml"
    config["soap_service_ids"].each do |id|
      assert validate_endpoint_xml_output(make_url("/soap_services/#{id}"))
      assert validate_endpoint_xml_output(make_url("/soap_services/#{id}/operations"))
      assert validate_endpoint_xml_output(make_url("/soap_services/#{id}/deployments"))
      assert validate_endpoint_xml_output(make_url("/soap_services/#{id}/annotations"))
    end
  end
  
  def test_soap_operations
    assert validate_endpoint_xml_output(make_url("/soap_operations"))
    assert validate_endpoint_xml_output(make_url("/soap_operations?page=2"))
    assert validate_endpoint_xml_output(make_url("/soap_operations?page=3&per_page=5"))
    assert validate_endpoint_xml_output(make_url("/soap_operations?page=2&include=inputs,ancestors&per_page=3"))
    assert validate_endpoint_xml_output(make_url("/soap_operations?sort_by=created&sort_order=asc"))
    assert validate_endpoint_xml_output(make_url("/soap_operations?tag=[blast]"))
    assert validate_endpoint_xml_output(make_url("/soap_operations?tag=[blast],[predicting]"))
    assert validate_endpoint_xml_output(make_url("/soap_operations?tag_ins=[blast],[predicting]&tag_outs=[blast_report]"))
  end
  
  def test_soap_operations_filters
    assert validate_endpoint_xml_output(make_url("/soap_operations/filters"))
  end
  
  def test_soap_operation
    assert config["soap_operation_ids"].length > 0, "No soap_operation_ids found in config.yml"
    config["soap_operation_ids"].each do |id|
      assert validate_endpoint_xml_output(make_url("/soap_operations/#{id}"))
      assert validate_endpoint_xml_output(make_url("/soap_operations/#{id}/annotations"))
      assert validate_endpoint_xml_output(make_url("/soap_operations/#{id}/annotations?include=inputs"))
      assert validate_endpoint_xml_output(make_url("/soap_operations/#{id}/annotations?include=inputs,outputs"))
    end
  end
  
  def test_soap_input
    assert config["soap_input_ids"].length > 0, "No soap_input_ids found in config.yml"
    config["soap_input_ids"].each do |id|
      assert validate_endpoint_xml_output(make_url("/soap_inputs/#{id}"))
      assert validate_endpoint_xml_output(make_url("/soap_inputs/#{id}/annotations"))
    end
  end
  
  def test_soap_output
    assert config["soap_output_ids"].length > 0, "No soap_output_ids found in config.yml"
    config["soap_output_ids"].each do |id|
      assert validate_endpoint_xml_output(make_url("/soap_outputs/#{id}"))
      assert validate_endpoint_xml_output(make_url("/soap_outputs/#{id}/annotations"))
    end
  end
  
  def test_rest_service
    assert config["rest_service_ids"].length > 0, "No rest_service_ids found in config.yml"
    config["rest_service_ids"].each do |id|
      assert validate_endpoint_xml_output(make_url("/rest_services/#{id}"))
      assert validate_endpoint_xml_output(make_url("/rest_services/#{id}/deployments"))
      assert validate_endpoint_xml_output(make_url("/rest_services/#{id}/annotations"))
    end
  end
  
  def test_categories
    assert validate_endpoint_xml_output(make_url("/categories"))
    assert validate_endpoint_xml_output(make_url("/categories?roots_only=false"))
    assert validate_endpoint_xml_output(make_url("/categories?roots_only=true"))
  end
  
  def test_category
    assert config["category_ids"].length > 0, "No category_ids found in config.yml"
    config["category_ids"].each do |id|
      assert validate_endpoint_xml_output(make_url("/categories/#{id}"))
      assert validate_endpoint_xml_output(make_url("/categories/#{id}/services"))
    end
  end
  
  def test_tags
    assert validate_endpoint_xml_output(make_url("/tags"))
    assert validate_endpoint_xml_output(make_url("/tags?page=2"))
    assert validate_endpoint_xml_output(make_url("/tags?per_page=20"))
    assert validate_endpoint_xml_output(make_url("/tags?per_page=25&page=3"))
    assert validate_endpoint_xml_output(make_url("/tags?sort=name&page=3"))
    assert validate_endpoint_xml_output(make_url("/tags?sort=counts&page=2"))
  end
  
  def test_tag
    assert config["tag_endpoints"].length > 0, "No tag_endpoints found in config.yml"
    config["tag_endpoints"].each do |e|
      assert validate_endpoint_xml_output(make_url(e))
    end
  end
  
  def test_service_providers
    assert validate_endpoint_xml_output(make_url("/service_providers"))
    assert validate_endpoint_xml_output(make_url("/service_providers?page=2"))
    assert validate_endpoint_xml_output(make_url("/service_providers?sort_by=created&sort_order=asc"))
    assert validate_endpoint_xml_output(make_url("/service_providers?sort_by=created&sort_order=asc&page=2"))
  end
  
  def test_service_provider
    assert config["service_provider_ids"].length > 0, "No service_provider_ids found in config.yml"
    config["service_provider_ids"].each do |id|
      assert validate_endpoint_xml_output(make_url("/service_providers/#{id}"))
      assert validate_endpoint_xml_output(make_url("/service_providers/#{id}/services"))
      assert validate_endpoint_xml_output(make_url("/service_providers/#{id}/annotations"))
      assert validate_endpoint_xml_output(make_url("/service_providers/#{id}/annotations_by"))
    end
  end
  
  def test_users
    assert validate_endpoint_xml_output(make_url("/users"))
    assert validate_endpoint_xml_output(make_url("/users?page=2"))
    assert validate_endpoint_xml_output(make_url("/users?sort_by=activated&sort_order=asc"))
    assert validate_endpoint_xml_output(make_url("/users?sort_by=activated&sort_order=asc&page=2"))
  end
  
  def test_user
    assert config["user_ids"].length > 0, "No user_ids found in config.yml"
    config["user_ids"].each do |id|
      assert validate_endpoint_xml_output(make_url("/users/#{id}"))
      assert validate_endpoint_xml_output(make_url("/users/#{id}/services"))
      assert validate_endpoint_xml_output(make_url("/users/#{id}/annotations_by"))
    end
  end
  
  def test_registries
    assert validate_endpoint_xml_output(make_url("/registries"))
    assert validate_endpoint_xml_output(make_url("/registries?sort_by=created&sort_order=asc"))
    assert validate_endpoint_xml_output(make_url("/registries?sort_by=created&sort_order=asc&page=2"))
  end
  
  def test_registry
    assert config["registry_ids"].length > 0, "No registry_ids found in config.yml"
    config["registry_ids"].each do |id|
      assert validate_endpoint_xml_output(make_url("/registries/#{id}"))
      assert validate_endpoint_xml_output(make_url("/registries/#{id}/services"))
      assert validate_endpoint_xml_output(make_url("/registries/#{id}/annotations_by"))
    end
  end
  
  def test_annotation_attributes
    assert validate_endpoint_xml_output(make_url("/annotation_attributes"))
    assert validate_endpoint_xml_output(make_url("/annotation_attributes?page=2"))
  end
  
  def test_annotation_attribute
    assert config["annotation_attribute_ids"].length > 0, "No annotation_attribute_ids found in config.yml"
    config["annotation_attribute_ids"].each do |id|
      assert validate_endpoint_xml_output(make_url("/annotation_attributes/#{id}"))
      assert validate_endpoint_xml_output(make_url("/annotation_attributes/#{id}/annotations"))
    end
  end
  
  def test_annotations
    assert validate_endpoint_xml_output(make_url("/annotations"))
    assert validate_endpoint_xml_output(make_url("/annotations?page=2"))
    assert validate_endpoint_xml_output(make_url("/annotations?page=3"))
    assert validate_endpoint_xml_output(make_url("/annotations?page=4"))
    assert validate_endpoint_xml_output(make_url("/annotations?page=5"))
    # TODO: filtered pages!
  end
  
  def test_annotations_filters
    assert validate_endpoint_xml_output(make_url("/annotations/filters"))
  end
  
  def test_annotation
    assert config["annotation_ids"].length > 0, "No annotation_ids found in config.yml"
    config["annotation_ids"].each do |id|
      assert validate_endpoint_xml_output(make_url("/annotations/#{id}"))  
    end
  end
  
  def test_service_test
    assert config["service_test_ids"].length > 0, "No service_test_ids found in config.yml"
    config["service_test_ids"].each do |id|
      assert validate_endpoint_xml_output(make_url("/service_tests/#{id}"))
      assert validate_endpoint_xml_output(make_url("/service_tests/#{id}/results"))  
    end
  end
  
  def test_test_results
    assert validate_endpoint_xml_output(make_url("/test_results"))
    assert validate_endpoint_xml_output(make_url("/test_results?page=2"))
    
    assert config["service_test_ids_for_test_results"].length > 0, "No service_test_ids_for_test_results found in config.yml"
    config["service_test_ids_for_test_results"].each do |id|
      assert validate_endpoint_xml_output(make_url("/test_results?service_test_id=#{id}"))  
    end
  end
  
  def test_test_result
    assert config["test_result_ids"].length > 0, "No test_result_ids found in config.yml"
    config["test_result_ids"].each do |id|
      assert validate_endpoint_xml_output(make_url("/test_results/#{id}"))  
    end
  end
  
  def teardown
  end
  
end

