require 'test_helper'

class TestScriptTest < ActiveSupport::TestCase
  
  def setup
    @new_script        = TestScript.new
    @script_with_data  = Factory(:test_script_with_user)
  end
  
  test "should not be valid without associated user" do
    script_with_data = @script_with_data
    assert script_with_data.valid?
    script_with_data.user  = nil
    assert !script_with_data.valid?," test script valid without associated user"  
  end
  
  test "should not be valid with illegal content type" do
    script_with_data = @script_with_data
    assert script_with_data.valid?, "invalid script"
    script_with_data.content_type  = 'illegal_content_type'
    assert !script_with_data.valid? , "script valid with illegal content type: #{script_with_data.content_type}"
  end
  
  test "should not be valid without a file name" do
    script_with_data = @script_with_data
    assert script_with_data.valid?, "invalid script"
    script_with_data.filename  = nil
    assert !script_with_data.valid? , " test script valid  without a file name "
  end
  
  test "should not be valid without description" do
    script_with_data = @script_with_data
    assert script_with_data.valid?
    script_with_data.description  = nil
    assert !script_with_data.valid?," test script valid without description"  
  end
  
  test "should not be valid without name" do
    script_with_data = @script_with_data
    assert script_with_data.valid?
    script_with_data.name  = nil
    assert !script_with_data.valid?," test script valid without name"  
  end
  
  test "should not be valid without executable name" do
    script_with_data = @script_with_data
    assert script_with_data.valid?
    script_with_data.exec_name  = nil
    assert !script_with_data.valid?," test script valid without executable name"  
  end
  
  test "should not be valid with illegal programming language" do
    script_with_data = @script_with_data
    assert script_with_data.valid?, "invalid script"
    script_with_data.prog_language  = 'illegal_programming_language'
    assert !script_with_data.valid? , "script valid with illegal programming language: #{script_with_data.prog_language}"
  end
  
  test "new script should have no recent status history" do
    @new_script.service_test = ServiceTest.new
    assert_equal @new_script.recent_test_results, [], "New test script has test results"
  end
  
  test "new script should have unchecked status" do
    @new_script.service_test = ServiceTest.new
    assert_equal @new_script.latest_test_result.result, 
                  TestResult.new_with_unknown_status.result,  "New test script status is different from Unchecked "
  end
  
  test "should return user associated with test script" do
    script = Factory(:test_script_with_user)
    assert_equal script, TestScript.find_tests_by_user(script.user)[0], "Did not return user associated with test"
  end
  
end
