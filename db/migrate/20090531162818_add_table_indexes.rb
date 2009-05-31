class AddTableIndexes < ActiveRecord::Migration
  def self.up
    
    add_index :agents, [ "name" ], :name => "agents_name_index"
    
    add_index :registries, [ "name" ], :name => "registries_name_index"
    
    add_index :relationships, [ "predicate" ], :name => "relationships_predicate_index"
    add_index :relationships, [ "subject_type", "subject_id" ], :name => "relationships_subject_index"
    add_index :relationships, [ "object_type", "object_id" ], :name => "relationships_object_index"
    
    add_index :rest_method_parameters, [ "rest_parameter_id" ], :name => "rest_method_params_param_id_index"
    
    add_index :rest_method_representations, [ "rest_method_id" ], :name => "rest_method_reps_method_id_index"
    add_index :rest_method_representations, [ "rest_method_id", "http_cycle" ], :name => "rest_method_reps_method_id_cycle_index"
    
    add_index :rest_methods, [ "rest_resource_id", "method_type" ], :name => "rest_methods_rest_resource_id_method_type_index"
    
    add_index :rest_resources, [ "parent_resource_id" ], :name => "rest_resources_rest_parent_resource_id_index"
    
    add_index :service_deployments, [ "service_id" ], :name => "service_deployments_service_id_index"
    add_index :service_deployments, [ "service_version_id" ], :name => "service_deployments_service_version_id_index"
    add_index :service_deployments, [ "endpoint" ], :name => "service_deployments_endpoint_index"
    add_index :service_deployments, [ "service_provider_id" ], :name => "service_deployments_service_provider_id_index"
    add_index :service_deployments, [ "country" ], :name => "service_deployments_country_index"
    add_index :service_deployments, [ "submitter_type", "submitter_id" ], :name => "service_deployments_submitter_index"
    
    add_index :service_providers, [ "name" ], :name => "service_providers_name_index"
    
    add_index :service_versions, [ "service_id" ], :name => "service_versions_service_id_index"
    add_index :service_versions, [ "service_versionified_type", "service_versionified_id" ], :name => "service_versions_service_versionified_index"
    add_index :service_versions, [ "service_id", "version" ], :name => "service_versions_service_id_version_index"
    add_index :service_versions, [ "submitter_type", "submitter_id" ], :name => "service_versions_submitter_index"
    
    add_index :services, [ "unique_code" ], :name => "services_unique_code_index"
    add_index :services, [ "name" ], :name => "services_name_index"
    add_index :services, [ "submitter_type", "submitter_id" ], :name => "services_submitter_index"
    
    add_index :soap_services, [ "name" ], :name => "soap_services_name_index"
    add_index :soap_services, [ "wsdl_location" ], :name => "soap_services_wsdl_location_index"
    
    add_index :soaplab_servers, [ "location" ], :name => "soaplab_servers_location_index"
    
    add_index :test_results, [ "test_type", "test_id" ], :name => "test_results_test_index"
    
    add_index :url_monitors, [ "parent_type", "parent_id" ], :name => "url_monitors_parent_index"
    
    add_index :users, [ "email" ], :name => "users_email_index"
    add_index :users, [ "display_name" ], :name => "users_display_name_index"
    
  end

  def self.down
    
    remove_index :agents, :name => "agents_name_index"
    
    remove_index :registries, :name => "registries_name_index"
    
    remove_index :relationships, :name => "relationships_predicate_index"
    remove_index :relationships, :name => "relationships_subject_index"
    remove_index :relationships, :name => "relationships_object_index"
    
    remove_index :rest_method_parameters, :name => "rest_method_params_param_id_index"
    
    remove_index :rest_method_representations, :name => "rest_method_reps_method_id_index"
    remove_index :rest_method_representations, :name => "rest_method_reps_method_id_cycle_index"
    
    remove_index :rest_methods, :name => "rest_methods_rest_resource_id_method_type_index"
    
    remove_index :rest_resources, :name => "rest_resources_rest_parent_resource_id_index"
    
    remove_index :service_deployments, :name => "service_deployments_service_id_index"
    remove_index :service_deployments, :name => "service_deployments_service_version_id_index"
    remove_index :service_deployments, :name => "service_deployments_endpoint_index"
    remove_index :service_deployments, :name => "service_deployments_service_provider_id_index"
    remove_index :service_deployments, :name => "service_deployments_country_index"
    remove_index :service_deployments, :name => "service_deployments_submitter_index"
    
    remove_index :service_providers, :name => "service_providers_name_index"
    
    remove_index :service_versions, :name => "service_versions_service_id_index"
    remove_index :service_versions, :name => "service_versions_service_versionified_index"
    remove_index :service_versions, :name => "service_versions_service_id_version_index"
    remove_index :service_versions, :name => "service_versions_submitter_index"
    
    remove_index :services, :name => "services_unique_code_index"
    remove_index :services, :name => "services_name_index"
    remove_index :services, :name => "services_submitter_index"
    
    remove_index :soap_services, :name => "soap_services_name_index"
    remove_index :soap_services, :name => "soap_services_wsdl_location_index"
    
    remove_index :soaplab_servers, :name => "soaplab_servers_location_index"
    
    remove_index :test_result, :name => "test_results_test_index"
    
    remove_index :url_monitors, :name => "url_monitors_parent_index"
    
    remove_index :users, :name => "users_email_index"
    remove_index :users, :name => "users_display_name_index"
    
  end
end
