$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../lib')
require 'test/unit'
require 'rubygems'
require 'activerecord'
require 'after_commit'
require 'after_commit/active_record'
require 'after_commit/connection_adapters'

ActiveRecord::Base.establish_connection({"adapter" => "sqlite3", "database" => 'test.sqlite3'})
begin
  ActiveRecord::Base.connection.execute("drop table mock_records");
rescue
end
ActiveRecord::Base.connection.execute("create table mock_records(id int)");

require File.dirname(__FILE__) + '/../init.rb'

class MockRecord < ActiveRecord::Base
  attr_accessor :before_commit_on_create_called
  attr_accessor :before_commit_on_update_called
  attr_accessor :before_commit_on_destroy_called
  attr_accessor :after_commit_on_create_called
  attr_accessor :after_commit_on_update_called
  attr_accessor :after_commit_on_destroy_called

  before_commit_on_create :do_before_create
  def do_before_create
    self.before_commit_on_create_called = true
  end

  before_commit_on_update :do_before_update
  def do_before_update
    self.before_commit_on_update_called = true
  end

  before_commit_on_create :do_before_destroy
  def do_before_destroy
    self.before_commit_on_destroy_called = true
  end

  after_commit_on_create :do_after_create
  def do_after_create
    self.after_commit_on_create_called = true
  end

  after_commit_on_update :do_after_update
  def do_after_update
    self.after_commit_on_update_called = true
  end

  after_commit_on_create :do_after_destroy
  def do_after_destroy
    self.after_commit_on_destroy_called = true
  end
end

class AfterCommitTest < Test::Unit::TestCase
  def test_before_commit_on_create_is_called
    assert_equal true, MockRecord.create!.before_commit_on_create_called
  end

  def test_before_commit_on_update_is_called
    record = MockRecord.create!
    record.save
    assert_equal true, record.before_commit_on_update_called
  end

  def test_before_commit_on_destroy_is_called
    assert_equal true, MockRecord.create!.destroy.before_commit_on_destroy_called
  end

  def test_after_commit_on_create_is_called
    assert_equal true, MockRecord.create!.after_commit_on_create_called
  end

  def test_after_commit_on_update_is_called
    record = MockRecord.create!
    record.save
    assert_equal true, record.after_commit_on_update_called
  end

  def test_after_commit_on_destroy_is_called
    assert_equal true, MockRecord.create!.destroy.after_commit_on_destroy_called
  end
end
