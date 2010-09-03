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

  def validate_data_from_path(path)
    data = load_data_from_endpoint(make_url(path))
    assert data.is_a?(Hash), data_incorrect_class_msg(data, path)
    assert !data.empty?, data_empty_msg(path, Hash)
    return data
  end

  def validate_filters_from_path(path)
    # TODO: validate internals some more
    data = load_data_from_endpoint(make_url(path))
    assert data.is_a?(Array), data_incorrect_class_msg(data, path)
    return data
  end

  # ========================================
  
  def validate_index_from_path(path, allow_empty=false, allowed_size=10)
    data = validate_data_from_path(make_url(path))
    resource_name = data.keys.first
    
    assert !data[resource_name].nil?, element_nil_msg(resource_name, path)

    assert !data[resource_name]['per_page'].nil?, element_nil_msg("#{resource_name}:per_page", path)
    assert data[resource_name]['per_page'].is_a?(Fixnum), data_incorrect_class_msg(data[resource_name]['per_page'], path)
    assert !data[resource_name]['pages'].nil?, element_nil_msg("#{resource_name}:pages", path)
    assert data[resource_name]['pages'].is_a?(Fixnum), data_incorrect_class_msg(data[resource_name]['pages'], path)
    assert !data[resource_name]['current_page'].nil?, element_nil_msg("#{resource_name}:current_page", path)
    assert data[resource_name]['current_page'].is_a?(Fixnum), data_incorrect_class_msg(data[resource_name]['current_page'], path)
    assert !data[resource_name]['total'].nil?, element_nil_msg("#{resource_name}:total", path)
    assert data[resource_name]['total'].is_a?(Fixnum), data_incorrect_class_msg(data[resource_name]['total'], path)
    
    validate_collection_from_data_given_path(data[resource_name]['results'], path, allow_empty, allowed_size)
  end
  
  def validate_collection_from_data_given_path(data, path, allow_empty=true, allowed_size=50)
    assert !data.nil?, element_nil_msg("results::collection", path)
    assert data.is_a?(Array), data_incorrect_class_msg(data, path)

    assert !data.empty?, data_empty_msg(path, Array) unless allow_empty    
    assert data.length <= allowed_size, "'#{path}' yields too many elements."
    
    proceed = !path.include?('/services') && 
              !path.include?('/annotations') && 
              !path.include?('/tags') && 
              !path.include?('/rest_parameters') && 
              !path.include?('/service_providers')
              
    if proceed
      data.each do |listing|
        assert listing['self'].nil?, "The collection at path '#{path}' contains an object with 'self'"
        assert !listing['resource'].nil?, element_nil_msg("results::collection:resource", path)
      end
    end
  end
  
  # ========================================
  
  # TODO: test the model internals a little bit more

  def validate_agent_from_path(path)
    data = validate_data_from_path(path)
    assert !data['agent'].nil?, element_nil_msg('agent', path)

    assert !data['agent']['self'].nil?, element_nil_msg('agent:self', path)
    assert !data['agent']['name'].nil?, element_nil_msg('agent:name', path)
  end

  def validate_annotation_attribute_from_path(path)
    data = validate_data_from_path(path)
    assert !data['annotation_attribute'].nil?, element_nil_msg('annotation_attribute', path)

    assert !data['annotation_attribute']['self'].nil?, element_nil_msg('annotation_attribute:self', path)
    assert !data['annotation_attribute']['name'].nil?, element_nil_msg('annotation_attribute:name', path)
    assert !data['annotation_attribute']['identifier'].nil?, element_nil_msg('annotation_attribute:identifier', path)
  end
  
  def validate_annotation_from_path(path)
    data = validate_data_from_path(path)
    assert !data['annotation'].nil?, element_nil_msg('annotation', path)

    assert !data['annotation']['self'].nil?, element_nil_msg('annotation:self', path)
    assert !data['annotation']['value'].nil?, element_nil_msg('annotation:value', path)
    assert !data['annotation']['attribute'].nil?, element_nil_msg('annotation:attribute', path)
    assert !data['annotation']['source'].nil?, element_nil_msg('annotation:source', path)
    assert !data['annotation']['annotatable'].nil?, element_nil_msg('annotation:annotatable', path)
  end
  
  def validate_category_from_path(path)
    data = validate_data_from_path(path)
    assert !data['category'].nil?, element_nil_msg('category', path)

    assert !data['category']['self'].nil?, element_nil_msg('category:self', path)
    assert !data['category']['name'].nil?, element_nil_msg('category:name', path)      
    assert !data['category']['total_items_count'].nil?, element_nil_msg('category:total_items_count', path)      
  end

  def validate_lookup_from_path(path)
    data = validate_data_from_path(path)
    resource_name = data.keys.first
    eval "validate_#{resource_name}_from_path('#{path}')"
  end
  
  def validate_registry_from_path(path)
    data = validate_data_from_path(path)
    assert !data['registry'].nil?, element_nil_msg('registry', path)

    assert !data['registry']['self'].nil?, element_nil_msg('registry:self', path)
    assert !data['registry']['name'].nil?, element_nil_msg('registry:name', path)
    assert !data['registry']['homepage'].nil?, element_nil_msg('registry:homepage', path)    
  end

  def validate_rest_method_from_path(path, action=:show)
    data = validate_data_from_path(path)
    assert !data['rest_method'].nil?, element_nil_msg('rest_method', path)

    assert !data['rest_method']['self'].nil?, element_nil_msg('rest_method:self', path)
    assert !data['rest_method']['endpoint_label'].nil?, element_nil_msg('rest_method:endpoint_label', path)
    assert !data['rest_method']['http_method_type'].nil?, element_nil_msg('rest_method:http_method_type', path)    
    assert !data['rest_method']['url_template'].nil?, element_nil_msg('rest_method:url_template', path)    
    assert !data['rest_method']['submitter'].nil?, element_nil_msg('rest_method:submitter', path)
    
    if action==:show || action==:inputs
      assert data['rest_method']['inputs'].is_a?(Hash), data_incorrect_class_msg(data['rest_method']['inputs'], path)

      validate_collection_from_data_given_path(data['rest_method']['inputs']['parameters'], path)
      validate_collection_from_data_given_path(data['rest_method']['inputs']['representations'], path)
    end

    if action==:show || action==:outputs
      assert data['rest_method']['outputs'].is_a?(Hash), data_incorrect_class_msg(data['rest_method']['outputs'], path)

      validate_collection_from_data_given_path(data['rest_method']['outputs']['parameters'], path)
      validate_collection_from_data_given_path(data['rest_method']['outputs']['representations'], path)
    end
  end

  def validate_rest_parameter_from_path(path)
    data = validate_data_from_path(path)
    assert !data['rest_parameter'].nil?, element_nil_msg('rest_parameter', path)

    assert !data['rest_parameter']['self'].nil?, element_nil_msg('rest_parameter:self', path)
    assert !data['rest_parameter']['name'].nil?, element_nil_msg('rest_parameter:name', path)
    assert !data['rest_parameter']['param_style'].nil?, element_nil_msg('rest_parameter:param_style', path)

    validate_collection_from_data_given_path(data['rest_parameter']['constrained_values'], path, true, 100)
  end

  def validate_rest_representation_from_path(path)
    data = validate_data_from_path(path)
    assert !data['rest_representation'].nil?, element_nil_msg('rest_representation', path)

    assert !data['rest_representation']['self'].nil?, element_nil_msg('rest_representation:self', path)
    assert !data['rest_representation']['content_type'].nil?, element_nil_msg('rest_representation:content_type', path)
  end

  def validate_rest_resource_from_path(path, action=:show)
    data = validate_data_from_path(path)
    assert !data['rest_resource'].nil?, element_nil_msg('rest_resource', path)

    assert !data['rest_resource']['self'].nil?, element_nil_msg('rest_resource:self', path)
    assert !data['rest_resource']['path'].nil?, element_nil_msg('rest_resource:path', path)
    assert !data['rest_resource']['submitter'].nil?, element_nil_msg('rest_resource:submitter', path)
    
    if action==:methods || action==:show
      validate_collection_from_data_given_path(data['rest_resource']['methods'], path)
    end
  end

  def validate_rest_service_from_path(path, action=:show)
    data = validate_data_from_path(path)
    assert !data['rest_service'].nil?, element_nil_msg('rest_service', path)

    assert !data['rest_service']['self'].nil?, element_nil_msg('rest_service:self', path)
    assert !data['rest_service']['name'].nil?, element_nil_msg('rest_service:name', path)
    assert !data['rest_service']['submitter'].nil?, element_nil_msg('rest_service:submitter', path)

    if action==:show || action==:deployments
      validate_collection_from_data_given_path(data['rest_service']['deployments'], path)
    end

    if action==:show || action==:resources
      validate_collection_from_data_given_path(data['rest_service']['resources'], path)
    end

    if action==:methods
      validate_collection_from_data_given_path(data['rest_service']['methods'], path)
    end

  end

  def validate_service_from_path(path, action=:show)
    data = validate_data_from_path(path)
    assert !data['service'].nil?, element_nil_msg('service', path)

    assert !data['service']['self'].nil?, element_nil_msg('service:self', path)
    assert !data['service']['name'].nil?, element_nil_msg('service:name', path)
    assert !data['service']['latest_monitoring_status'].nil?, element_nil_msg('service:latest_monitoring_status', path)
    assert !data['service']['submitter'].nil?, element_nil_msg('service:submitter', path)
    
    validate_collection_from_data_given_path(data['service']['service_technology_types'], path)
    
    if action==:show || action==:deployments
      validate_collection_from_data_given_path(data['service']['deployments'], path)
    end

    if action==:show || action==:variants
      validate_collection_from_data_given_path(data['service']['variants'], path)
    end
    
    if action==:summary
      assert data['service']['summary'].is_a?(Hash), data_incorrect_class_msg(data['service']['summary'], path)
    end

    if action==:monitoring
      validate_collection_from_data_given_path(data['service']['service_tests'], path)
    end
  end

  def validate_service_deployment_from_path(path)
    data = validate_data_from_path(path)
    assert !data['service_deployment'].nil?, element_nil_msg('service_deployment', path)

    assert !data['service_deployment']['self'].nil?, element_nil_msg('service_deployment:self', path)
    assert !data['service_deployment']['endpoint'].nil?, element_nil_msg('service_deployment:endpoint', path)
    assert !data['service_deployment']['provided_variant'].nil?, element_nil_msg('service_deployment:provided_variant', path)
    assert !data['service_deployment']['provider'].nil?, element_nil_msg('service_deployment:provider', path)
    assert !data['service_deployment']['submitter'].nil?, element_nil_msg('service_deployment:submitter', path)
    assert !data['service_deployment']['location'].nil?, element_nil_msg('service_deployment:location', path)
  end

  def validate_service_provider_from_path(path)
    data = validate_data_from_path(path)
    assert !data['service_provider'].nil?, element_nil_msg('service_provider', path)

    assert !data['service_provider']['self'].nil?, element_nil_msg('service_provider:self', path)
    assert !data['service_provider']['name'].nil?, element_nil_msg('service_provider:name', path)
    
    validate_collection_from_data_given_path(data['service_provider']['hostnames'], path)
  end

  def validate_service_test_from_path(path)
    data = validate_data_from_path(path)
    assert !data['service_test'].nil?, element_nil_msg('service_test', path)

    assert !data['service_test']['self'].nil?, element_nil_msg('service_test:self', path)
    assert !data['service_test']['test_type'].nil?, element_nil_msg('service_test:test_type', path)
    assert !data['service_test']['status'].nil?, element_nil_msg('service_test:status', path)
  end

  def validate_soap_input_from_path(path)
    data = validate_data_from_path(path)
    assert !data['soap_input'].nil?, element_nil_msg('soap_input', path)

    assert !data['soap_input']['self'].nil?, element_nil_msg('soap_input:self', path)
    assert !data['soap_input']['name'].nil?, element_nil_msg('soap_input:name', path)
  end

  def validate_soap_output_from_path(path)
    data = validate_data_from_path(path)
    assert !data['soap_output'].nil?, element_nil_msg('soap_output', path)

    assert !data['soap_output']['self'].nil?, element_nil_msg('soap_output:self', path)
    assert !data['soap_output']['name'].nil?, element_nil_msg('soap_output:name', path)
  end

  def validate_soap_operation_from_path(path, action=:show)
    data = validate_data_from_path(path)
    assert !data['soap_operation'].nil?, element_nil_msg('soap_operation', path)

    assert !data['soap_operation']['self'].nil?, element_nil_msg('soap_operation:self', path)
    assert !data['soap_operation']['name'].nil?, element_nil_msg('soap_operation:name', path)
    
    if action==:show || :action==:inputs
      validate_collection_from_data_given_path(data['soap_operation']['inputs'], path)
    end
    
    if action==:show || :action==:outputs
      validate_collection_from_data_given_path(data['soap_operation']['outputs'], path)
    end
  end

  def validate_soap_service_from_path(path, action=:show)
    data = validate_data_from_path(path)
    assert !data['soap_service'].nil?, element_nil_msg('soap_service', path)

    assert !data['soap_service']['self'].nil?, element_nil_msg('soap_service:self', path)
    assert !data['soap_service']['name'].nil?, element_nil_msg('soap_service:name', path)
    assert !data['soap_service']['submitter'].nil?, element_nil_msg('soap_service:submitter', path)
    assert !data['soap_service']['wsdl_location'].nil?, element_nil_msg('soap_service:wsdl_location', path)

    if action==:show || :action==:deployments
      validate_collection_from_data_given_path(data['soap_service']['deployments'], path)
    end
    
    if action==:show || :action==:operations
      validate_collection_from_data_given_path(data['soap_service']['operations'], path)
    end
  end

  def validate_tag_from_path(path)
    data = validate_data_from_path(path)
    assert !data['tag'].nil?, element_nil_msg('tag', path)

    assert !data['tag']['display_name'].nil?, element_nil_msg('tag:display_name', path)
    assert !data['tag']['name'].nil?, element_nil_msg('tag:name', path)
    assert !data['tag']['total_items_count'].nil?, element_nil_msg('tag:total_items_count', path)
  end

  def validate_test_result_from_path(path)
    data = validate_data_from_path(path)
    assert !data['test_result'].nil?, element_nil_msg('test_result', path)

    assert !data['test_result']['self'].nil?, element_nil_msg('test_result:self', path)
    assert !data['test_result']['test_action'].nil?, element_nil_msg('test_result:test_action', path)
    assert !data['test_result']['status'].nil?, element_nil_msg('test_result:status', path)
    assert !data['test_result']['result_code'].nil?, element_nil_msg('test_result:result_code', path)
  end

  def validate_user_from_path(path, action=:show)
    data = validate_data_from_path(path)
    assert !data['user'].nil?, element_nil_msg('user', path)

    assert !data['user']['self'].nil?, element_nil_msg('user:self', path)
    assert !data['user']['name'].nil?, element_nil_msg('user:name', path)
    assert !data['user']['location'].nil?, element_nil_msg('user:location', path)
    assert !data['user']['joined'].nil?, element_nil_msg('user:joined', path)
    
    if action==:saved_searches
      validate_collection_from_data_given_path(data['user']['saved_searches'], path)
    end

  end
  
end
