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
    required_config_elements = %w{ agent_ids annotation_ids annotation_attribute_ids category_ids registry_ids
                                   rest_method_ids rest_parameter_ids rest_representation_ids rest_resource_ids
                                   rest_service_ids search_queries service_ids service_deployment_ids 
                                   service_provider_ids service_test_ids soap_input_ids soap_operation_ids 
                                   soap_output_ids  soap_service_ids tag_endpoints test_result_ids user_ids wsdl_locations }.freeze
    
    required_config_elements.each { |element|
      assert config[element].length > 0, "No '#{element}' element found in config.yml"
    }
  end

  # --------------------

  # root
  def test_root
    assert validate_endpoint_xml_output(make_url("/"))
  end

  # agent
  def test_agents
    assert validate_endpoint_xml_output(make_url("/agents"))
    assert validate_endpoint_xml_output(make_url("/agents?sort_by=created&sort_order=asc"))
  end
  
  def test_agent
    config["agent_ids"].each do |id|
      assert validate_endpoint_xml_output(make_url("/agents/#{id}"))
      assert validate_endpoint_xml_output(make_url("/agents/#{id}/annotations_by"))
    end
  end

  # annotation_attribute
  def test_annotation_attributes
    assert validate_endpoint_xml_output(make_url("/annotation_attributes"))
    assert validate_endpoint_xml_output(make_url("/annotation_attributes?page=2"))
  end
  
  def test_annotation_attribute
    config["annotation_attribute_ids"].each do |id|
      assert validate_endpoint_xml_output(make_url("/annotation_attributes/#{id}"))
      assert validate_endpoint_xml_output(make_url("/annotation_attributes/#{id}/annotations"))
    end
  end

  # annotation
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
    config["annotation_ids"].each do |id|
      assert validate_endpoint_xml_output(make_url("/annotations/#{id}"))  
    end
  end

  # category
  def test_categories
    assert validate_endpoint_xml_output(make_url("/categories"))
    assert validate_endpoint_xml_output(make_url("/categories?roots_only=false"))
    assert validate_endpoint_xml_output(make_url("/categories?roots_only=true"))
  end
  
  def test_category
    config["category_ids"].each do |id|
      assert validate_endpoint_xml_output(make_url("/categories/#{id}"))
      assert validate_endpoint_xml_output(make_url("/categories/#{id}/services"))
    end
  end

  # lookup
  def test_lookup
    config["wsdl_locations"].each { |wsdl| 
      validate_endpoint_xml_output(make_url("/lookup?wsdl_location=#{wsdl}"))
    }
  end

  # registry
  def test_registries
    assert validate_endpoint_xml_output(make_url("/registries"))
    assert validate_endpoint_xml_output(make_url("/registries?sort_by=created&sort_order=asc"))
    assert validate_endpoint_xml_output(make_url("/registries?sort_by=created&sort_order=asc&page=2"))
  end
  
  def test_registry
    config["registry_ids"].each do |id|
      assert validate_endpoint_xml_output(make_url("/registries/#{id}"))
      assert validate_endpoint_xml_output(make_url("/registries/#{id}/services"))
      assert validate_endpoint_xml_output(make_url("/registries/#{id}/annotations_by"))
    end
  end

  # rest_method
  def test_rest_methods
    assert validate_endpoint_xml_output(make_url("/rest_methods"))
    assert validate_endpoint_xml_output(make_url("/rest_methods?page=2"))
  end
  
  def test_rest_method
    config["rest_method_ids"].each { |id| 
      assert validate_endpoint_xml_output(make_url("/rest_methods/#{id}")) 
      assert validate_endpoint_xml_output(make_url("/rest_methods/#{id}/inputs")) 
      assert validate_endpoint_xml_output(make_url("/rest_methods/#{id}/outputs")) 
      assert validate_endpoint_xml_output(make_url("/rest_methods/#{id}/annotations")) 
    }
  end

  # rest_parameter
  def test_rest_parameter
    config["rest_parameter_ids"].each { |id| 
      assert validate_endpoint_xml_output(make_url("/rest_parameters/#{id}")) 
      assert validate_endpoint_xml_output(make_url("/rest_parameters/#{id}/annotations")) 
    }
  end

  # rest_representation
  def test_rest_representation
    config["rest_representation_ids"].each { |id| 
      assert validate_endpoint_xml_output(make_url("/rest_representations/#{id}")) 
      assert validate_endpoint_xml_output(make_url("/rest_representations/#{id}/annotations")) 
    }
  end

  # rest_resource
  def test_rest_resources
    assert validate_endpoint_xml_output(make_url("/rest_resources"))
    assert validate_endpoint_xml_output(make_url("/rest_resources?page=2"))
  end
  
  def test_rest_resource
    config["rest_resource_ids"].each { |id| 
      assert validate_endpoint_xml_output(make_url("/rest_resources/#{id}")) 
      assert validate_endpoint_xml_output(make_url("/rest_resources/#{id}/annotations")) 
      assert validate_endpoint_xml_output(make_url("/rest_resources/#{id}/methods")) 
    }
  end

  # rest_service
  def test_rest_services
    assert validate_endpoint_xml_output(make_url("/rest_services"))
    assert validate_endpoint_xml_output(make_url("/rest_services?page=2"))
  end

  def test_rest_service
    config["rest_service_ids"].each do |id|
      assert validate_endpoint_xml_output(make_url("/rest_services/#{id}"))
      assert validate_endpoint_xml_output(make_url("/rest_services/#{id}/deployments"))
      assert validate_endpoint_xml_output(make_url("/rest_services/#{id}/resources"))
      assert validate_endpoint_xml_output(make_url("/rest_services/#{id}/annotations"))
    end
  end

  # search
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

  # service
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

  # service_deployment
  def test_service_deployment
    config["service_deployment_ids"].each do |id|
      assert validate_endpoint_xml_output(make_url("/service_deployments/#{id}"))
      assert validate_endpoint_xml_output(make_url("/service_deployments/#{id}/annotations"))
    end
  end

  # service_provider
  def test_service_providers
    assert validate_endpoint_xml_output(make_url("/service_providers"))
    assert validate_endpoint_xml_output(make_url("/service_providers?page=2"))
    assert validate_endpoint_xml_output(make_url("/service_providers?sort_by=created&sort_order=asc"))
    assert validate_endpoint_xml_output(make_url("/service_providers?sort_by=created&sort_order=asc&page=2"))
  end
  
  def test_service_provider
    config["service_provider_ids"].each do |id|
      assert validate_endpoint_xml_output(make_url("/service_providers/#{id}"))
      assert validate_endpoint_xml_output(make_url("/service_providers/#{id}/services"))
      assert validate_endpoint_xml_output(make_url("/service_providers/#{id}/annotations"))
      assert validate_endpoint_xml_output(make_url("/service_providers/#{id}/annotations_by"))
    end
  end

  # service_test
  def test_service_test
    config["service_test_ids"].each do |id|
      assert validate_endpoint_xml_output(make_url("/service_tests/#{id}"))
      assert validate_endpoint_xml_output(make_url("/service_tests/#{id}/results"))  
    end
  end

  # soap_input
  def test_soap_input
    config["soap_input_ids"].each do |id|
      assert validate_endpoint_xml_output(make_url("/soap_inputs/#{id}"))
      assert validate_endpoint_xml_output(make_url("/soap_inputs/#{id}/annotations"))
    end
  end

  # soap_operation
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
    config["soap_operation_ids"].each do |id|
      assert validate_endpoint_xml_output(make_url("/soap_operations/#{id}"))
      assert validate_endpoint_xml_output(make_url("/soap_operations/#{id}/annotations"))
      assert validate_endpoint_xml_output(make_url("/soap_operations/#{id}/annotations?include=inputs"))
      assert validate_endpoint_xml_output(make_url("/soap_operations/#{id}/annotations?include=inputs,outputs"))
    end
  end
    
  # soap_output
  def test_soap_output
    config["soap_output_ids"].each do |id|
      assert validate_endpoint_xml_output(make_url("/soap_outputs/#{id}"))
      assert validate_endpoint_xml_output(make_url("/soap_outputs/#{id}/annotations"))
    end
  end

  # soap_service
  def test_soap_services
    assert validate_endpoint_xml_output(make_url("/soap_services"))
    assert validate_endpoint_xml_output(make_url("/soap_services?page=2"))
  end

  def test_soap_service
    config["soap_service_ids"].each do |id|
      assert validate_endpoint_xml_output(make_url("/soap_services/#{id}"))
      assert validate_endpoint_xml_output(make_url("/soap_services/#{id}/operations"))
      assert validate_endpoint_xml_output(make_url("/soap_services/#{id}/deployments"))
      assert validate_endpoint_xml_output(make_url("/soap_services/#{id}/annotations"))
    end
  end
  
  # tags
  def test_tags
    assert validate_endpoint_xml_output(make_url("/tags"))
    assert validate_endpoint_xml_output(make_url("/tags?page=2"))
    assert validate_endpoint_xml_output(make_url("/tags?per_page=20"))
    assert validate_endpoint_xml_output(make_url("/tags?per_page=25&page=3"))
    assert validate_endpoint_xml_output(make_url("/tags?sort=name&page=3"))
    assert validate_endpoint_xml_output(make_url("/tags?sort=counts&page=2"))
  end
  
  def test_tag
    config["tag_endpoints"].each do |e|
      assert validate_endpoint_xml_output(make_url(e))
    end
  end
  
  # test_results
  def test_test_results
    assert validate_endpoint_xml_output(make_url("/test_results"))
    assert validate_endpoint_xml_output(make_url("/test_results?page=2"))
    
    config["service_test_ids"].each do |id|
      assert validate_endpoint_xml_output(make_url("/test_results?service_test_id=#{id}"))  
    end
  end
  
  def test_test_result
    config["test_result_ids"].each do |id|
      assert validate_endpoint_xml_output(make_url("/test_results/#{id}"))  
    end
  end
  
  # user
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

  # --------------------
  
  def teardown
  end
  
end

