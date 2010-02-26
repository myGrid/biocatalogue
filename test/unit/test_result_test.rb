require 'test_helper'

class TestResultTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
  
  def setup
    @result = TestResult.new
  end
  
  test "must be associated with a service test" do
    assert !@result.service_test_id, "Not associated with a service test"
  end
  
  test "must have a result value" do
    assert !@result.result, "No result value not set "
  end
  
  test "result is an integer greater than -1" do
    assert !@result.valid_result_range, "Invalid result value"
  end
  
  test "should not accept invalid result" do
    result = TestResult.new(:result => -20)
    assert !result.valid_result_range, "Accepted invalid result"
  end
  
  def teardown
    @result.destroy
  end
end
