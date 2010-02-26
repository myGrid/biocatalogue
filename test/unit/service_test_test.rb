require 'test_helper'

class ServiceTestTest < ActiveSupport::TestCase
  
  def setup
    @service_test = Factory(:script_service_test_with_result)
  end
  
  test "should not be valid without a test type" do
    service_test = @service_test
    assert service_test.valid?
    service_test.test_type = nil
    assert !service_test.valid?
  end
  
  test "should not be valid without an associated service" do
    service_test = @service_test
    assert service_test.valid?
    service_test.service = nil
    assert !service_test.valid?
  end
  
  test "should return single test result " do
    service_test = @service_test
    assert_equal 1, service_test.test_results.length, "Number of test results was #{service_test.test_results.length} : 1 expected"
  end
  
  test "should return the lastest 5 test results " do
    service_test = @service_test
    assert service_test.recent_test_results.length < 6
  end
  
  test "should return latest result " do
    service_test = @service_test
    assert_equal service_test.latest_test_result, service_test.test_results.last
  end
  
end
