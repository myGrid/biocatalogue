# BioCatalogue: script/biocatalogue/api/tests/json_tests.rb
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# Tests JSON outputs.
# NOTE: this relies on their being a large dataset to test against (ie: lots of data in the db!)

require 'test/unit'
require File.join(File.dirname(__FILE__), 'json_test_helper')

class JsonTests < Test::Unit::TestCase
  
  include JsonTestHelper

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
  # TODO: add more tests (include query parameters)
  
  # --------------------
  
  # root
  def test_root
    validate_data_from_path("/")
  end
  
  # agent
  def test_agents
    validate_index_from_path("/agents")
    validate_index_from_path("/agents?sort_by=created&sort_order=asc")
  end

  def test_agent
    config["agent_ids"].each { |id| 
      validate_agent_from_path("/agents/#{id}") 
      validate_index_from_path("/agents/#{id}/annotations_by")
    }
  end
  
  # annotation_attribute
  def test_annotation_attributes
    validate_index_from_path("/annotation_attributes")
    validate_index_from_path("/annotation_attributes?page=2")
  end
  
  def test_annotation_attribute
    config["annotation_attribute_ids"].each { |id|
      validate_annotation_attribute_from_path("/annotation_attributes/#{id}") 
      validate_index_from_path("/annotation_attributes/#{id}/annotations")
    }
  end

  # annotation
  def test_annotations
    validate_index_from_path("/annotations")
    validate_index_from_path("/annotations?page=2")
    validate_index_from_path("/annotations?page=3")    
    validate_index_from_path("/annotations?page=4") 
    validate_index_from_path("/annotations?page=5")
  end

  def test_annotations_filters
    validate_filters_from_path("/annotations/filters")
  end

  def test_annotation
    config["annotation_ids"].each { |id| validate_annotation_from_path("/annotations/#{id}") }
  end
  
  # category
  def test_categories
    validate_index_from_path("/categories")
    validate_index_from_path("/categories?page=2")
  end
  
  def test_category
    config["category_ids"].each { |id| 
      validate_category_from_path("/categories/#{id}") 
      validate_index_from_path("/categories/#{id}/services")
    }
  end

  # lookup
  def test_lookup
    config["wsdl_locations"].each { |wsdl| validate_lookup_from_path("/lookup?wsdl_location=#{wsdl}") }
  end

  # registry
  def test_registries
    validate_index_from_path("/registries")
    validate_index_from_path("/registries?sort_by=created&sort_order=asc")
    validate_index_from_path("/registries?sort_by=created&sort_order=asc&page=2", true)
  end
  
  def test_registry
    config["registry_ids"].each { |id| 
      validate_registry_from_path("/registries/#{id}") 
      validate_index_from_path("/registries/#{id}/annotations_by")
      validate_index_from_path("/registries/#{id}/services") 
    }
  end

  # rest_method
  def test_rest_methods
    validate_index_from_path("/rest_methods")
    validate_index_from_path("/rest_methods?page=2")
    validate_index_from_path("/rest_methods?sort_by=name")
    validate_index_from_path("/rest_methods?sort_by=name&sort_order=desc")
    validate_index_from_path("/rest_methods?sort_by=name&sort_order=asc")
    validate_index_from_path("/rest_methods?q=database", true)    
  end

  def test_rest_methods_filters
    validate_filters_from_path("/rest_methods/filters")
  end

  def test_rest_method
    config["rest_method_ids"].each { |id| 
      validate_rest_method_from_path("/rest_methods/#{id}") 
      validate_rest_method_from_path("/rest_methods/#{id}/inputs", :inputs)
      validate_rest_method_from_path("/rest_methods/#{id}/outputs", :outputs)
      validate_index_from_path("/rest_methods/#{id}/annotations")
    }
  end

  # rest_parameter
  def test_rest_parameter
    config["rest_parameter_ids"].each { |id| 
      validate_rest_parameter_from_path("/rest_parameters/#{id}") 
      validate_index_from_path("/rest_parameters/#{id}/annotations", true)
    }
  end

  # rest_representation
  def test_rest_representation
    config["rest_representation_ids"].each { |id| 
      validate_rest_representation_from_path("/rest_representations/#{id}") 
      validate_index_from_path("/rest_representations/#{id}/annotations", true)
    }
  end

  # rest_resource
  def test_rest_resources
    validate_index_from_path("/rest_resources")
    validate_index_from_path("/rest_resources?page=2")
  end
  
  def test_rest_resource
    config["rest_resource_ids"].each { |id| 
      validate_rest_resource_from_path("/rest_resources/#{id}") 
      validate_rest_resource_from_path("/rest_resources/#{id}/methods", :methods) 
      validate_index_from_path("/rest_resources/#{id}/annotations", true)
    }
  end
  
  # rest_service
  def test_rest_services
    validate_index_from_path("/rest_services")
    validate_index_from_path("/rest_services?page=2")
  end
  
  def test_rest_service
    config["rest_service_ids"].each { |id|
      validate_rest_service_from_path("/rest_services/#{id}") 
      validate_rest_service_from_path("/rest_services/#{id}/deployments", :deployments) 
      validate_rest_service_from_path("/rest_services/#{id}/resources", :resources) 
      validate_index_from_path("/rest_services/#{id}/annotations")
    }
  end

  # search
  def test_search
    config["search_queries"].each { |query| 
      validate_index_from_path("/search?q=#{query}", true)
      validate_index_from_path("/search?q=#{query}&page=2", true)
      validate_index_from_path("/search?q=#{query}&page=3", true)
      validate_index_from_path("/search?q=#{query}&page=4", true)
      validate_index_from_path("/search?q=#{query}&page=5", true)
      validate_index_from_path("/search?q=#{query}&scope=services", true)
      validate_index_from_path("/search?q=#{query}&scope=services&page=2", true)
      validate_index_from_path("/search?q=#{query}&scope=service_providers", true)
      validate_index_from_path("/search?q=#{query}&scope=services,service_providers", true)
      validate_index_from_path("/search?q=#{query}&scope=services&include=summary", true)
      validate_index_from_path("/search?q=#{query}&scope=services&include=summary,related", true)
    }
  end

  # service
  def test_services
    validate_index_from_path("/services")
    validate_index_from_path("/services?page=2")
    validate_index_from_path("/services?per_page=5", false, 5)
    validate_index_from_path("/services?per_page=5&page=3", false, 5)
    validate_index_from_path("/services?t=[SOAP]")
    validate_index_from_path("/services?t=[SOAP]&per_page=3&page=3", false, 3)
    validate_index_from_path("/services?t=[SOAP]&p=[1],[3],[5]")
    validate_index_from_path("/services?t=[SOAP]&p=[1]&c=[United+Kingdom]")
    validate_index_from_path("/services?t=[SOAP]&per_page=1&page=3", false, 1)
    validate_index_from_path("/services?include=summary")
    validate_index_from_path("/services?include=summary&page=2&per_page=20", false, 20)
    validate_index_from_path("/services?sort_by=created&sort_order=asc")
    validate_index_from_path("/services?sort_by=created&sort_order=asc&page=3")

  end

  def test_services_filters
    validate_filters_from_path("/services/filters")
  end
  
  def test_service
    config["service_ids"].each { |id| 
      validate_service_from_path("/services/#{id}") 
      validate_service_from_path("/services/#{id}/deployments", :deployments) 
      validate_service_from_path("/services/#{id}/variants", :variants) 
      validate_service_from_path("/services/#{id}/monitoring", :monitoring) 
      validate_index_from_path("/services/#{id}/annotations")
    }
  end
  
  # service_deployment
  def test_service_deployment
    config["service_deployment_ids"].each { |id|
      validate_service_deployment_from_path("/service_deployments/#{id}") 
      validate_index_from_path("/service_deployments/#{id}/annotations", true)
    }
  end

  # service_provider
  def test_service_providers
    validate_index_from_path("/service_providers")
    validate_index_from_path("/service_providers?page=2")
    validate_index_from_path("/service_providers?sort_by=created&sort_order=asc")
    validate_index_from_path("/service_providers?sort_by=created&sort_order=asc&page=2")
    validate_index_from_path("/service_providers?sort_by=name")
    validate_index_from_path("/service_providers?sort_by=name&sort_order=desc")
    validate_index_from_path("/service_providers?sort_by=name&sort_order=asc")
    validate_index_from_path("/service_providers?q=ddbj", true)
    validate_index_from_path("/service_providers?c=[japan]")
  end
  
  def test_service_providers_filters
    validate_filters_from_path("/service_providers/filters")
  end

  def test_service_provider
    config["service_provider_ids"].each { |id| 
      validate_service_provider_from_path("/service_providers/#{id}") 
      validate_index_from_path("/service_providers/#{id}/services")
      validate_index_from_path("/service_providers/#{id}/annotations")
      validate_index_from_path("/service_providers/#{id}/annotations_by", true)
    }
  end

  # service_test
  def test_service_test
    config["service_test_ids"].each { |id| 
      validate_service_test_from_path("/service_tests/#{id}") 
      validate_index_from_path("/service_tests/#{id}/results")
    }
  end
  
  # soap_input
  def test_soap_input
    config["soap_input_ids"].each { |id|
      validate_soap_input_from_path("/soap_inputs/#{id}") 
      validate_index_from_path("/soap_inputs/#{id}/annotations", true)
    }
  end

  # soap_operation
  def test_soap_operations
    validate_index_from_path("/soap_operations")
    validate_index_from_path("/soap_operations?page=2")
    validate_index_from_path("/soap_operations?page=3&per_page=5", false, 5)
    validate_index_from_path("/soap_operations?page=2&include=inputs,ancestors&per_page=3", false, 3)
    validate_index_from_path("/soap_operations?sort_by=created&sort_order=asc")
    validate_index_from_path("/soap_operations?tag=[blast]")
    validate_index_from_path("/soap_operations?tag=[blast],[predicting]")
    validate_index_from_path("/soap_operations?tag_ins=[blast],[predicting]&tag_outs=[blast_report]", true)
  end

  def test_soap_operations_filters
    validate_filters_from_path("/soap_operations/filters")
  end
  
  def test_soap_operation
    config["soap_operation_ids"].each { |id| 
      validate_soap_operation_from_path("/soap_operations/#{id}") 
      validate_soap_operation_from_path("/soap_operations/#{id}/inputs", :inputs) 
      validate_soap_operation_from_path("/soap_operations/#{id}/outputs", :outputs) 
      validate_index_from_path("/soap_operations/#{id}/annotations")
    }
  end
  
  # soap_output
  def test_soap_output
    config["soap_output_ids"].each { |id|
      validate_soap_output_from_path("/soap_outputs/#{id}") 
      validate_index_from_path("/soap_outputs/#{id}/annotations", true)
    }
  end

  # soap_service
  def test_soap_services
    validate_index_from_path("/soap_services")
    validate_index_from_path("/soap_services?page=2")
  end
  
  def test_soap_service
    config["soap_service_ids"].each { |id| 
      validate_soap_service_from_path("/soap_services/#{id}") 
      validate_soap_service_from_path("/soap_services/#{id}/deployments", :deployments) 
      validate_soap_service_from_path("/soap_services/#{id}/operations", :operations) 
      validate_index_from_path("/soap_services/#{id}/annotations")
    }
  end

  # tags
  def test_tags
    validate_index_from_path("/tags")
    validate_index_from_path("/tags?page=2")
    validate_index_from_path("/tags?per_page=20", false, 20)
    validate_index_from_path("/tags?per_page=25&page=3", false, 25)
    validate_index_from_path("/tags?sort=name&page=3")
    validate_index_from_path("/tags?sort=counts&page=2")
  end
  
  def test_tag
    config["tag_endpoints"].each { |path| validate_tag_from_path(path) }
  end

  # test_results
  def test_test_results
    validate_index_from_path("/test_results")
    validate_index_from_path("/test_results?page=2")
    
    config["service_test_ids"].each { |id|
      validate_index_from_path("/test_results?service_test_id=#{id}")
    }
  end
  
  def test_test_result
    config["test_result_ids"].each { |id| validate_test_result_from_path("/test_results/#{id}") }
  end

  # user
  def test_users
    validate_index_from_path("/users")
    validate_index_from_path("/users?page=2")
    validate_index_from_path("/users?sort_by=activated&sort_order=asc")
    validate_index_from_path("/users?sort_by=activated&sort_order=asc&page=2")
    validate_index_from_path("/users?sort_by=name")
    validate_index_from_path("/users?sort_by=name&sort_order=desc")
    validate_index_from_path("/users?sort_by=name&sort_order=asc")
    validate_index_from_path("/users?q=franck", true)
    validate_index_from_path("/users?c=[japan]")
  end

  def test_users_filters
    validate_filters_from_path("/users/filters")
  end

  def test_user
    config["user_ids"].each { |id| 
      validate_user_from_path("/users/#{id}") 
      validate_index_from_path("/users/#{id}/annotations_by", true)
      validate_index_from_path("/users/#{id}/services", true)
    }
  end

  # --------------------
  
  def teardown
  end

end

