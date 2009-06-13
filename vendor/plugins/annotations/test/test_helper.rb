Dir.chdir(File.join(File.dirname(__FILE__), "..")) do

  ENV['RAILS_ENV'] = 'mysql'
  RAILS_ENV = 'mysql'
  
  RAILS_GEM_VERSION = '2.3.2' unless defined? RAILS_GEM_VERSION
  
  HELPER_RAILS_ROOT = File.join(Dir.pwd, "test", "app_root")
  RAILS_ROOT = File.join(Dir.pwd, "test", "app_root")
  
  # Load the plugin testing framework
  require 'rubygems'
  require 'plugin_test_helper'
  
  # Run the migrations (optional)
  ActiveRecord::Migrator.migrate("#{Rails.root}/db/migrate")
  
  require 'init'
  
  ActiveSupport::TestCase.class_eval do
    self.use_transactional_fixtures = true
    self.use_instantiated_fixtures  = false
    self.fixture_path = File.join(Dir.pwd, "test", "fixtures")
  
    set_fixture_class :books => Book,
                      :chapters => Chapter,
                      :users => User,
                      :groups => Group,
                      :annotations => Annotation,
                      :annotation_versions => Annotation::Version,
                      :annotation_attributes => AnnotationAttribute,
                      :annotation_value_seeds => AnnotationValueSeed
  
    fixtures :all
  end

end