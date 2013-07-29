require 'test_helper'

class TestResultsControllerTest < ActionController::TestCase
  
  def setup
    @user = Factory(:user)
    @service_test = Factory(:script_service_test_with_result)
  end
  

  test "should create test_result" do
    session[:user_id] = @user.id

    assert_difference('TestResult.count') do
      post :create, :test_result => {:result => 0, 
                                      :message => 'test passed', 
                                      :action  => 'simple test', 
                                      :service_test_id => @service_test.id  },
           :format => 'xml'
    end
    
    assert_response(:created)
  end
  
  test "should not create test_result without authenticated user " do
    session[:user_id] = nil
    count = TestResult.count
    post :create, :test_result => {:result => 0, 
                                      :message => 'test passed', 
                                      :action  => 'simple test', 
                                      :service_test_id => @service_test.id  },
         :format => 'xml'
    
    assert_equal(count, TestResult.count, "result created without an authenticated user")
    assert_response(:found)
    
  end

end
