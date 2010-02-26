class AddIndexesForNewServiceTestTables < ActiveRecord::Migration
  def self.up
    add_index :test_results, [ :service_test_id ], :name => "test_results_stest_id_index"
    
    add_index :service_tests, [ :test_type ], :name => "s_tests_test_type_index"
    add_index :service_tests, [ :test_type, :test_id ], :name => "s_tests_test_type_id_index"
    add_index :service_tests, [ :service_id ], :name => "s_tests_service_id_index"
    
    add_index :external_tests, [ :user_id ], :name => "e_tests_user_id_index"
    
    add_index :test_scripts, [ :user_id ], :name => "t_scripts_user_id_index"
    add_index :test_scripts, [ :prog_language ], :name => "t_scripts_prog_lang_index"
  end

  def self.down
    remove_index :test_result, :name => "test_results_stest_id_index"
    
    remove_index :service_tests, :name => "s_tests_test_type_index"
    remove_index :service_tests, :name => "s_tests_test_type_id_index"
    remove_index :service_tests, :name => "s_tests_service_id_index"
    
    remove_index :external_tests, :name => "e_tests_user_id_index"
    
    remove_index :test_scripts, :name => "t_scripts_user_id_index"
    remove_index :test_scripts, :name => "t_scripts_prog_lang_index"
  end
end
