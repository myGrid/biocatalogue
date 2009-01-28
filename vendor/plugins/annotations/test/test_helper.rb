ENV['RAILS_ENV'] = 'mysql'

RAILS_ROOT = "#{File.dirname(__FILE__)}/app_root"

require 'rubygems'
require 'active_record'
require 'plugin_test_helper'

ActiveRecord::Migrator.migrate("#{Rails.root}/db/migrate")

require "#{File.dirname(__FILE__)}/../init"

Test::Unit::TestCase.class_eval do
  self.use_transactional_fixtures = true
  self.use_instantiated_fixtures  = false
  self.fixture_path = "#{File.dirname(__FILE__)}/app_root/test/fixtures"

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