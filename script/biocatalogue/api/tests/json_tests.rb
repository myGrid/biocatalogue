# BioCatalogue: script/biocatalogue/api/tests/json_tests.rb
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# Tests JSON outputs.
# NOTE: this relies on their being a large dataset to test against (ie: lots of data in the db!)

require 'test/unit'
require File.join(File.dirname(__FILE__), 'json_test_helper')

class XmlSchemaValidations < Test::Unit::TestCase
  
  include JsonTestHelper

  def setup
  end

  def test_annotations
    data1 = load_data_from_endpoint(make_url("/annotations"))
    assert data1.is_a?(Array), "Result not of the correct data type. Is a #{data1.class.name}."
    assert !data1.empty?, "No annotations JSON data found"
    assert data1.length <= 10, "Too many annotations"
    
    data2 = load_data_from_endpoint(make_url("/annotations?page=2"))
    assert data2.is_a?(Array), "Result not of the correct data type. Is a #{data2.class.name}."
    assert !data2.empty?, "No annotations JSON data found"
    assert data2.length <= 10, "Too many annotations"
  end
  
  def test_annotation
    assert config["annotation_ids"].length > 0, "No annotation_ids found in config.yml"
    config["annotation_ids"].each do |id|
      data = load_data_from_endpoint(make_url("/annotations/#{id}"))
      assert data.is_a?(Hash), "Result not of the correct data type. Is a #{data.class.name}."
      assert !data.empty?, "No annotations JSON data found for Annotation ID: #{id}"
      # TODO: test the internals a little bit more
    end
  end
  
  def test_annotation_attributes
    data1 = load_data_from_endpoint(make_url("/annotation_attributes"))
    assert data1.is_a?(Array), "Result not of the correct data type. Is a #{data1.class.name}."
    assert !data1.empty?, "No annotation attributes JSON data found"
    assert data1.length <= 10, "Too many annotation attributes"
    
    data2 = load_data_from_endpoint(make_url("/annotation_attributes?page=2"))
    assert data2.is_a?(Array), "Result not of the correct data type. Is a #{data2.class.name}."
    assert !data2.empty?, "No annotation attributes JSON data found"
    assert data2.length <= 10, "Too many annotation attributes"
  end
  
  def test_annotation_attribute
    assert config["annotation_attribute_ids"].length > 0, "No annotation_attribute_ids found in config.yml"
    config["annotation_attribute_ids"].each do |id|
      
      data1 = load_data_from_endpoint(make_url("/annotation_attributes/#{id}"))
      assert data1.is_a?(Hash), "Result not of the correct data type. Is a #{data1.class.name}."
      assert !data1.empty?, "No annotation attributes JSON data found for AnnotationAttribute ID: #{id}"
      # TODO: test the internals a little bit more
      
      data2 = load_data_from_endpoint(make_url("/annotation_attributes/#{id}/annotations"))
      assert data2.is_a?(Array), "Result not of the correct data type. Is a #{data2.class.name}."
      assert !data2.empty?, "No annotations JSON data found for AnnotationAttribute ID: #{id}"
      # TODO: test the internals a little bit more
      
    end
  end
  
  def test_registry
    assert config["registry_ids"].length > 0, "No registry_ids found in config.yml"
    config["registry_ids"].each do |id|
      
#      data1 = load_data_from_endpoint(make_url("/registries/#{id}"))
#      assert data1.is_a?(Hash), "Result not of the correct data type. Is a #{data1.class.name}."
#      assert !data1.empty?, "No registries JSON data found for Registry ID: #{id}"
#      # TODO: test the internals a little bit more
      
      data2 = load_data_from_endpoint(make_url("/registries/#{id}/annotations_by"))
      assert data2.is_a?(Array), "Result not of the correct data type. Is a #{data2.class.name}."
      assert !data2.empty?, "No annotations_by JSON data found for Registry ID: #{id}"
      # TODO: test the internals a little bit more
      
    end
  end
  
  def test_rest_service
    assert config["rest_service_ids"].length > 0, "No rest_service_ids found in config.yml"
    config["rest_service_ids"].each do |id|
      
#      data1 = load_data_from_endpoint(make_url("/rest_services/#{id}"))
#      assert data1.is_a?(Hash), "Result not of the correct data type. Is a #{data1.class.name}."
#      assert !data1.empty?, "No rest_services JSON data found for RestService ID: #{id}"
#      # TODO: test the internals a little bit more
      
      data2 = load_data_from_endpoint(make_url("/rest_services/#{id}/annotations"))
      assert data2.is_a?(Array), "Result not of the correct data type. Is a #{data2.class.name}."
      assert !data2.empty?, "No annotations JSON data found for RestService ID: #{id}"
      # TODO: test the internals a little bit more
      
    end
  end
  
  def test_service_deployment
    assert config["service_deployment_ids"].length > 0, "No service_deployment_ids found in config.yml"
    config["service_deployment_ids"].each do |id|
      
#      data1 = load_data_from_endpoint(make_url("/service_deployments/#{id}"))
#      assert data1.is_a?(Hash), "Result not of the correct data type. Is a #{data1.class.name}."
#      assert !data1.empty?, "No service_deployments JSON data found for ServiceDeployment ID: #{id}"
#      # TODO: test the internals a little bit more
      
      data2 = load_data_from_endpoint(make_url("/service_deployments/#{id}/annotations"))
      assert data2.is_a?(Array), "Result not of the correct data type. Is a #{data2.class.name}."
      assert !data2.empty?, "No annotations JSON data found for ServiceDeployment ID: #{id}"
      # TODO: test the internals a little bit more
      
    end
  end
  
  def test_service_provider
    assert config["service_provider_ids"].length > 0, "No service_provider_ids found in config.yml"
    config["service_provider_ids"].each do |id|
      
#      data1 = load_data_from_endpoint(make_url("/service_providers/#{id}"))
#      assert data1.is_a?(Hash), "Result not of the correct data type. Is a #{data1.class.name}."
#      assert !data1.empty?, "No service_providers JSON data found for ServiceProvider ID: #{id}"
#      # TODO: test the internals a little bit more
      
      data2 = load_data_from_endpoint(make_url("/service_providers/#{id}/annotations"))
      assert data2.is_a?(Array), "Result not of the correct data type. Is a #{data2.class.name}."
      assert !data2.empty?, "No annotations JSON data found for ServiceProvider ID: #{id}"
      # TODO: test the internals a little bit more
      
      data3 = load_data_from_endpoint(make_url("/service_providers/#{id}/annotations_by"))
      assert data3.is_a?(Array), "Result not of the correct data type. Is a #{data3.class.name}."
      assert !data3.empty?, "No annotations_by JSON data found for ServiceProvider ID: #{id}"
      # TODO: test the internals a little bit more
      
    end
  end
  
  def test_service
    assert config["service_ids"].length > 0, "No service_ids found in config.yml"
    config["service_ids"].each do |id|
      
#      data1 = load_data_from_endpoint(make_url("/services/#{id}"))
#      assert data1.is_a?(Hash), "Result not of the correct data type. Is a #{data1.class.name}."
#      assert !data1.empty?, "No services JSON data found for Service ID: #{id}"
#      # TODO: test the internals a little bit more
      
      data2 = load_data_from_endpoint(make_url("/services/#{id}/annotations"))
      assert data2.is_a?(Array), "Result not of the correct data type. Is a #{data2.class.name}."
      assert !data2.empty?, "No annotations JSON data found for Service ID: #{id}"
      # TODO: test the internals a little bit more
      
    end
  end
  
  def test_soap_input
    assert config["soap_input_ids"].length > 0, "No soap_input_ids found in config.yml"
    config["soap_input_ids"].each do |id|
      
#      data1 = load_data_from_endpoint(make_url("/soap_inputs/#{id}"))
#      assert data1.is_a?(Hash), "Result not of the correct data type. Is a #{data1.class.name}."
#      assert !data1.empty?, "No soap_inputs JSON data found for SoapInput ID: #{id}"
#      # TODO: test the internals a little bit more
      
      data2 = load_data_from_endpoint(make_url("/soap_inputs/#{id}/annotations"))
      assert data2.is_a?(Array), "Result not of the correct data type. Is a #{data2.class.name}."
      assert !data2.empty?, "No annotations JSON data found for SoapInput ID: #{id}"
      # TODO: test the internals a little bit more
      
    end
  end
  
  def test_soap_operation
    assert config["soap_operation_ids"].length > 0, "No soap_operation_ids found in config.yml"
    config["soap_operation_ids"].each do |id|
      
#      data1 = load_data_from_endpoint(make_url("/soap_operations/#{id}"))
#      assert data1.is_a?(Hash), "Result not of the correct data type. Is a #{data1.class.name}."
#      assert !data1.empty?, "No soap_operationss JSON data found for SoapOperation ID: #{id}"
#      # TODO: test the internals a little bit more
      
      data2 = load_data_from_endpoint(make_url("/soap_operations/#{id}/annotations"))
      assert data2.is_a?(Array), "Result not of the correct data type. Is a #{data2.class.name}."
      assert !data2.empty?, "No annotations JSON data found for SoapOperation ID: #{id}"
      # TODO: test the internals a little bit more
      
    end
  end
  
  def test_soap_output
    assert config["soap_output_ids"].length > 0, "No soap_output_ids found in config.yml"
    config["soap_output_ids"].each do |id|
      
#      data1 = load_data_from_endpoint(make_url("/soap_outputs/#{id}"))
#      assert data1.is_a?(Hash), "Result not of the correct data type. Is a #{data1.class.name}."
#      assert !data1.empty?, "No soap_outputs JSON data found for SoapOutput ID: #{id}"
#      # TODO: test the internals a little bit more
      
      data2 = load_data_from_endpoint(make_url("/soap_outputs/#{id}/annotations"))
      assert data2.is_a?(Array), "Result not of the correct data type. Is a #{data2.class.name}."
      assert !data2.empty?, "No annotations JSON data found for SoapOutput ID: #{id}"
      # TODO: test the internals a little bit more
      
    end
  end
  
  def test_soap_service
    assert config["soap_service_ids"].length > 0, "No soap_service_ids found in config.yml"
    config["soap_service_ids"].each do |id|
      
#      data1 = load_data_from_endpoint(make_url("/soap_services/#{id}"))
#      assert data1.is_a?(Hash), "Result not of the correct data type. Is a #{data1.class.name}."
#      assert !data1.empty?, "No soap_servicess JSON data found for SoapService ID: #{id}"
#      # TODO: test the internals a little bit more
      
      data2 = load_data_from_endpoint(make_url("/soap_services/#{id}/annotations"))
      assert data2.is_a?(Array), "Result not of the correct data type. Is a #{data2.class.name}."
      assert !data2.empty?, "No annotations JSON data found for SoapService ID: #{id}"
      # TODO: test the internals a little bit more
      
    end
  end
  
  def test_user
    assert config["user_ids"].length > 0, "No user_ids found in config.yml"
    config["user_ids"].each do |id|
      
#      data1 = load_data_from_endpoint(make_url("/users/#{id}"))
#      assert data1.is_a?(Hash), "Result not of the correct data type. Is a #{data1.class.name}."
#      assert !data1.empty?, "No userss JSON data found for User ID: #{id}"
#      # TODO: test the internals a little bit more
      
      data2 = load_data_from_endpoint(make_url("/users/#{id}/annotations_by"))
      assert data2.is_a?(Array), "Result not of the correct data type. Is a #{data2.class.name}."
      assert !data2.empty?, "No annotations_by JSON data found for User ID: #{id}"
      # TODO: test the internals a little bit more
      
    end
  end
  
  def teardown
  end
  
end

