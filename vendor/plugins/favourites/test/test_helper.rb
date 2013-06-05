Dir.chdir(File.join(File.dirname(__FILE__), "..")) do

  ENV['Rails.env'] = 'mysql'
  Rails.env = 'mysql'
  
  RAILS_GEM_VERSION = '2.3.2' unless defined? RAILS_GEM_VERSION
  
  HELPER_Rails.root = File.join(Dir.pwd, "test", "app_root")
  Rails.root = File.join(Dir.pwd, "test", "app_root")
  
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
                      :favourites => Favourite
  
    fixtures :all
  end

end