require 'test_helper'

class UrlMonitorTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
  
  def setup
    @monitor = UrlMonitor.new
  end
  
  test " must have a parent identifier" do
    assert !@monitor.parent_id, "Did not specify parent "
  end
  
  test "must specify parent type" do
    assert !@monitor.parent_type, "Did not specify parent type"
  end
  
  test "must be related to a property" do
    assert !@monitor.property, "Is not related to any property"
  end
end
