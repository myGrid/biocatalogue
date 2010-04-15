# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20100415085648) do

  create_table "activity_logs", :force => true do |t|
    t.string   "action",                 :limit => 60
    t.string   "activity_loggable_type", :limit => 60
    t.integer  "activity_loggable_id"
    t.string   "culprit_type",           :limit => 60
    t.integer  "culprit_id"
    t.string   "referenced_type",        :limit => 60
    t.integer  "referenced_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "data",                   :limit => 16777215
    t.string   "format"
    t.string   "http_referer"
    t.string   "user_agent"
  end

  add_index "activity_logs", ["action", "activity_loggable_type"], :name => "act_logs_forfeeds_index"
  add_index "activity_logs", ["action"], :name => "act_logs_action_index"
  add_index "activity_logs", ["activity_loggable_type", "activity_loggable_id"], :name => "act_logs_act_loggable_index"
  add_index "activity_logs", ["culprit_type", "culprit_id"], :name => "act_logs_culprit_index"
  add_index "activity_logs", ["format"], :name => "act_logs_format_index"
  add_index "activity_logs", ["referenced_type", "referenced_id"], :name => "act_logs_referenced_index"

  create_table "agents", :force => true do |t|
    t.string   "name"
    t.string   "display_name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "agents", ["name"], :name => "agents_name_index"

  create_table "annotation_attributes", :force => true do |t|
    t.string   "name",       :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "identifier", :null => false
  end

  add_index "annotation_attributes", ["name"], :name => "index_annotation_attributes_on_name"

  create_table "annotation_parsed_types", :force => true do |t|
    t.integer  "annotation_id", :null => false
    t.string   "parsed_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "annotation_properties", :force => true do |t|
    t.integer  "annotation_id",                                              :null => false
    t.string   "property_type",                                              :null => false
    t.integer  "property_id",                                                :null => false
    t.integer  "value",         :limit => 10, :precision => 10, :scale => 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "annotation_properties", ["property_type", "property_id"], :name => "annotation_properties_property_index"

  create_table "annotation_value_seeds", :force => true do |t|
    t.integer  "attribute_id", :null => false
    t.string   "value",        :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "annotation_value_seeds", ["attribute_id"], :name => "index_annotation_value_seeds_on_attribute_id"

  create_table "annotation_versions", :force => true do |t|
    t.integer  "annotation_id",                    :null => false
    t.integer  "version",                          :null => false
    t.integer  "version_creator_id"
    t.string   "source_type",                      :null => false
    t.integer  "source_id",                        :null => false
    t.string   "annotatable_type",   :limit => 50, :null => false
    t.integer  "annotatable_id",                   :null => false
    t.integer  "attribute_id",                     :null => false
    t.text     "value",                            :null => false
    t.string   "value_type",         :limit => 50, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "annotation_versions", ["annotation_id"], :name => "index_annotation_versions_on_annotation_id"

  create_table "annotations", :force => true do |t|
    t.string   "source_type",                                     :null => false
    t.integer  "source_id",                                       :null => false
    t.string   "annotatable_type",   :limit => 50,                :null => false
    t.integer  "annotatable_id",                                  :null => false
    t.integer  "attribute_id",                                    :null => false
    t.text     "value",                                           :null => false
    t.string   "value_type",         :limit => 50,                :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "version",                          :default => 1, :null => false
    t.integer  "version_creator_id"
  end

  add_index "annotations", ["annotatable_type", "annotatable_id"], :name => "index_annotations_on_annotatable_type_and_annotatable_id"
  add_index "annotations", ["attribute_id"], :name => "index_annotations_on_attribute_id"
  add_index "annotations", ["source_type", "source_id"], :name => "index_annotations_on_source_type_and_source_id"

  create_table "announcements", :force => true do |t|
    t.string   "item_type"
    t.integer  "item_id"
    t.integer  "user_id"
    t.string   "title"
    t.text     "body"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "categories", :force => true do |t|
    t.string   "name"
    t.integer  "parent_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "content_blobs", :force => true do |t|
    t.binary   "data",       :limit => 2147483647
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "data_search_regexes", :force => true do |t|
    t.string   "regex_name"
    t.string   "regex_value", :null => false
    t.string   "regex_type",  :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "delayed_jobs", :force => true do |t|
    t.integer  "priority",   :default => 0
    t.integer  "attempts",   :default => 0
    t.text     "handler"
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "external_tests", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.string   "doc_url"
    t.string   "provider_name"
    t.string   "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "external_tests", ["user_id"], :name => "e_tests_user_id_index"

  create_table "favourites", :force => true do |t|
    t.integer  "favouritable_id"
    t.string   "favouritable_type"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "favourites", ["favouritable_type", "favouritable_id"], :name => "favourites_favouritable_index"
  add_index "favourites", ["user_id"], :name => "favourites_user_id_index"

  create_table "registries", :force => true do |t|
    t.string   "name"
    t.string   "display_name"
    t.text     "description"
    t.string   "homepage"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "registries", ["name"], :name => "registries_name_index"

  create_table "relationships", :force => true do |t|
    t.string   "subject_type",       :null => false
    t.integer  "subject_id",         :null => false
    t.string   "predicate",          :null => false
    t.string   "object_type",        :null => false
    t.integer  "object_id",          :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "subject_field_name"
    t.string   "object_field_name"
  end

  add_index "relationships", ["object_type", "object_id"], :name => "relationships_object_index"
  add_index "relationships", ["predicate"], :name => "relationships_predicate_index"
  add_index "relationships", ["subject_type", "subject_id"], :name => "relationships_subject_index"

  create_table "responsibility_requests", :force => true do |t|
    t.integer  "user_id"
    t.integer  "subject_id"
    t.string   "subject_type"
    t.string   "status"
    t.string   "message"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "rest_method_parameters", :force => true do |t|
    t.integer  "rest_method_id",                        :null => false
    t.integer  "rest_parameter_id",                     :null => false
    t.string   "http_cycle",                            :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "submitter_id"
    t.string   "submitter_type",    :default => "User"
  end

  add_index "rest_method_parameters", ["rest_method_id", "http_cycle"], :name => "index_rest_method_parameters_on_rest_method_id_and_http_cycle"
  add_index "rest_method_parameters", ["rest_method_id"], :name => "index_rest_method_parameters_on_rest_method_id"
  add_index "rest_method_parameters", ["rest_parameter_id"], :name => "rest_method_params_param_id_index"

  create_table "rest_method_representations", :force => true do |t|
    t.integer  "rest_method_id",                             :null => false
    t.integer  "rest_representation_id",                     :null => false
    t.string   "http_cycle",                                 :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "submitter_id"
    t.string   "submitter_type",         :default => "User"
  end

  add_index "rest_method_representations", ["rest_method_id", "http_cycle"], :name => "rest_method_reps_method_id_cycle_index"
  add_index "rest_method_representations", ["rest_method_id"], :name => "rest_method_reps_method_id_index"
  add_index "rest_method_representations", ["rest_representation_id", "http_cycle"], :name => "index_rest_method_representations_repid_and_httpcycle"
  add_index "rest_method_representations", ["rest_representation_id"], :name => "index_rest_method_representations_on_rest_representation_id"

  create_table "rest_methods", :force => true do |t|
    t.integer  "rest_resource_id",                      :null => false
    t.string   "method_type",                           :null => false
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "submitter_id"
    t.string   "submitter_type",    :default => "User"
    t.string   "endpoint_name"
    t.string   "documentation_url"
  end

  add_index "rest_methods", ["rest_resource_id", "method_type"], :name => "rest_methods_rest_resource_id_method_type_index"
  add_index "rest_methods", ["rest_resource_id"], :name => "index_rest_methods_on_rest_resource_id"

  create_table "rest_parameters", :force => true do |t|
    t.string   "name",                                    :null => false
    t.text     "description"
    t.string   "param_style",                             :null => false
    t.string   "computational_type"
    t.string   "default_value"
    t.boolean  "required",            :default => false
    t.boolean  "multiple",            :default => false
    t.boolean  "constrained",         :default => false
    t.text     "constrained_options"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "submitter_id"
    t.string   "submitter_type",      :default => "User"
    t.boolean  "is_global",           :default => true,   :null => false
  end

  create_table "rest_representations", :force => true do |t|
    t.string   "content_type",                       :null => false
    t.text     "description"
    t.string   "http_status"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "submitter_id"
    t.string   "submitter_type", :default => "User"
  end

  create_table "rest_resources", :force => true do |t|
    t.integer  "rest_service_id",                        :null => false
    t.string   "path",                                   :null => false
    t.text     "description"
    t.integer  "parent_resource_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "submitter_id"
    t.string   "submitter_type",     :default => "User"
  end

  add_index "rest_resources", ["parent_resource_id"], :name => "rest_resources_rest_parent_resource_id_index"
  add_index "rest_resources", ["rest_service_id"], :name => "index_rest_resources_on_rest_service_id"

  create_table "rest_services", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "interface_doc_url"
    t.string   "documentation_url"
  end

  create_table "service_deployments", :force => true do |t|
    t.integer  "service_id"
    t.integer  "service_version_id"
    t.string   "endpoint"
    t.integer  "service_provider_id"
    t.string   "city"
    t.string   "country"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "submitter_id"
    t.string   "submitter_type"
  end

  add_index "service_deployments", ["country"], :name => "service_deployments_country_index"
  add_index "service_deployments", ["endpoint"], :name => "service_deployments_endpoint_index"
  add_index "service_deployments", ["service_id"], :name => "service_deployments_service_id_index"
  add_index "service_deployments", ["service_provider_id"], :name => "service_deployments_service_provider_id_index"
  add_index "service_deployments", ["service_version_id"], :name => "service_deployments_service_version_id_index"
  add_index "service_deployments", ["submitter_type", "submitter_id"], :name => "service_deployments_submitter_index"

  create_table "service_providers", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "service_providers", ["name"], :name => "service_providers_name_index"

  create_table "service_responsibles", :force => true do |t|
    t.integer  "user_id"
    t.integer  "service_id"
    t.string   "status"
    t.string   "message"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "service_tests", :force => true do |t|
    t.integer  "test_id"
    t.string   "test_type"
    t.integer  "service_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "service_tests", ["service_id"], :name => "s_tests_service_id_index"
  add_index "service_tests", ["test_type", "test_id"], :name => "s_tests_test_type_id_index"
  add_index "service_tests", ["test_type"], :name => "s_tests_test_type_index"

  create_table "service_versions", :force => true do |t|
    t.integer  "service_id"
    t.integer  "service_versionified_id"
    t.string   "service_versionified_type"
    t.string   "version"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "version_display_text"
    t.integer  "submitter_id"
    t.string   "submitter_type"
  end

  add_index "service_versions", ["service_id", "version"], :name => "service_versions_service_id_version_index"
  add_index "service_versions", ["service_id"], :name => "service_versions_service_id_index"
  add_index "service_versions", ["service_versionified_type", "service_versionified_id"], :name => "service_versions_service_versionified_index"
  add_index "service_versions", ["submitter_type", "submitter_id"], :name => "service_versions_submitter_index"

  create_table "services", :force => true do |t|
    t.string   "unique_code"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name"
    t.integer  "submitter_id"
    t.string   "submitter_type"
  end

  add_index "services", ["name"], :name => "services_name_index"
  add_index "services", ["submitter_type", "submitter_id"], :name => "services_submitter_index"
  add_index "services", ["unique_code"], :name => "services_unique_code_index"

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :null => false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "soap_inputs", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.integer  "soap_operation_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "computational_type"
    t.integer  "min_occurs"
    t.integer  "max_occurs"
    t.text     "computational_type_details", :limit => 16777215
  end

  add_index "soap_inputs", ["soap_operation_id"], :name => "index_soap_inputs_on_soap_operation_id"

  create_table "soap_operations", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.integer  "soap_service_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "parameter_order"
    t.string   "parent_port_type"
    t.integer  "soap_service_port_id"
  end

  add_index "soap_operations", ["soap_service_id"], :name => "index_soap_operations_on_soap_service_id"

  create_table "soap_outputs", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.integer  "soap_operation_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "computational_type"
    t.integer  "min_occurs"
    t.integer  "max_occurs"
    t.text     "computational_type_details", :limit => 16777215
  end

  add_index "soap_outputs", ["soap_operation_id"], :name => "index_soap_outputs_on_soap_operation_id"

  create_table "soap_service_ports", :force => true do |t|
    t.string   "name"
    t.string   "protocol"
    t.string   "style"
    t.string   "location"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "soap_service_id"
  end

  create_table "soap_services", :force => true do |t|
    t.string   "name"
    t.string   "wsdl_location"
    t.text     "description"
    t.string   "documentation_url"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "wsdl_file_id"
  end

  add_index "soap_services", ["name"], :name => "soap_services_name_index"
  add_index "soap_services", ["wsdl_location"], :name => "soap_services_wsdl_location_index"

  create_table "soaplab_servers", :force => true do |t|
    t.string   "name"
    t.string   "location"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "endpoint"
  end

  add_index "soaplab_servers", ["location"], :name => "soaplab_servers_location_index"

  create_table "test_results", :force => true do |t|
    t.integer  "result"
    t.string   "action"
    t.text     "message"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "service_test_id"
  end

  add_index "test_results", ["service_test_id"], :name => "test_results_stest_id_index"

  create_table "test_scripts", :force => true do |t|
    t.string   "name",                                :null => false
    t.string   "exec_name",                           :null => false
    t.text     "description",                         :null => false
    t.string   "filename",                            :null => false
    t.string   "content_type",                        :null => false
    t.integer  "submitter_id",                        :null => false
    t.integer  "content_blob_id",                     :null => false
    t.datetime "activated_at"
    t.string   "prog_language",                       :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "submitter_type",  :default => "User"
  end

  add_index "test_scripts", ["prog_language"], :name => "t_scripts_prog_lang_index"
  add_index "test_scripts", ["submitter_id"], :name => "t_scripts_user_id_index"

  create_table "trash_records", :force => true do |t|
    t.string   "trashable_type"
    t.integer  "trashable_id"
    t.binary   "data",           :limit => 16777215
    t.datetime "created_at"
  end

  add_index "trash_records", ["created_at", "trashable_type"], :name => "index_trash_records_on_created_at_and_trashable_type"
  add_index "trash_records", ["trashable_type", "trashable_id"], :name => "index_trash_records_on_trashable_type_and_trashable_id"

  create_table "url_monitors", :force => true do |t|
    t.integer  "parent_id"
    t.string   "parent_type"
    t.string   "property"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "activated_at", :default => '2010-04-15 10:08:14'
  end

  add_index "url_monitors", ["parent_type", "parent_id"], :name => "url_monitors_parent_index"

  create_table "users", :force => true do |t|
    t.string   "email"
    t.string   "crypted_password"
    t.string   "salt"
    t.datetime "activated_at"
    t.string   "security_token"
    t.string   "display_name"
    t.string   "openid_url"
    t.integer  "role_id"
    t.text     "affiliation"
    t.string   "country"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "public_email"
    t.boolean  "receive_notifications", :default => false
    t.string   "identifier"
    t.datetime "last_active"
  end

  add_index "users", ["display_name"], :name => "users_display_name_index"
  add_index "users", ["email"], :name => "users_email_index"

  create_table "wsdl_files", :force => true do |t|
    t.string   "location"
    t.integer  "content_blob_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
