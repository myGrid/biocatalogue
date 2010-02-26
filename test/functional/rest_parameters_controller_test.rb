require 'test_helper'

class RestParametersControllerTest < ActionController::TestCase
  test "get something without logging in" do
    get :new_popup
    assert_redirected_to :login
    
    get :add_new_parameters
    assert_redirected_to :login
    
    get :localise_globalise_parameter
    assert_redirected_to :login
  end
  
  test "get new popup" do
    rest = login_and_create_service_with_endpoints("put /3?name=doe")
    method = rest.rest_resources[0].rest_methods[0]
    
    get :new_popup, :rest_method_id => method.id
  end
  
  test "add new parameters" do
    rest = login_and_create_service_with_endpoints("/3")
    method = rest.rest_resources[0].rest_methods[0]
    
    assert_difference('RestParameter.count', 0) do # adding parameter that exists
      post :add_new_parameters, :rest_method_id => method.id, 
                                :rest_parameters => "id=43"
    end
    
    assert_difference('RestParameter.count', 1) do # adding one valid parameter (x=y) and one invalid parameter (x)
      post :add_new_parameters, :rest_method_id => method.id, 
                                :rest_parameters => "initial=jd \n id"
    end
  end
  
  test "add multiple parameters" do
    rest = login_and_create_service_with_endpoints("/workflow.xml")
    method = rest.rest_resources[0].rest_methods[0]
          
    assert_equal 0, RestParameter.count

    assert_difference('RestParameter.count', 3) do # adding multiple params
      post :add_new_parameters, :rest_method_id => method.id, 
                                :rest_parameters => "x=123 \n y=zxc\n z=abc"
    end
  end
  
  test "link and unlink parameter" do
    rest = login_and_create_service_with_endpoints("?id=3")
    method = rest.rest_resources[0].rest_methods[0]
    param = method.request_parameters[0]
    param_name = param.name
    
    # unlink
    assert_difference('RestParameter.count', 0) do
      post :localise_globalise_parameter, :id => param.id,
                                   :rest_method_id => method.id,
                                   :make_unique => true
    end
    
    assert_equal RestParameter.last.name, "UNIQUE_TO_METHOD_#{method.id}-#{param_name}"

    # link
    assert_difference('RestParameter.count', 0) do
      post :localise_globalise_parameter, :id => RestParameter.last.id,
                                   :rest_method_id => method.id,
                                   :make_unique => false
    end

    assert_not_equal RestParameter.last.name, "UNIQUE_TO_METHOD_#{method.id}-#{param_name}"
  end
  
  test "link and unlink parameter on a shared parameter" do
    rest = login_and_create_service_with_endpoints("/3 \n put /5?name=john+doe") # 'id' is the shared/common parameter
    method = rest.rest_resources[0].rest_methods[0]
    param = method.request_parameters[0]
    param_name = param.name
    
    # unlink
    assert_difference('RestParameter.count', 1) do
      post :localise_globalise_parameter, :id => param.id,
                                   :rest_method_id => method.id,
                                   :make_unique => true
    end
    
    assert_equal RestParameter.last.name, "UNIQUE_TO_METHOD_#{method.id}-#{param_name}"
    
    # link
    assert_difference('RestParameter.count', -1) do
      post :localise_globalise_parameter, :id => RestParameter.last.id,
                                   :rest_method_id => method.id,
                                   :make_unique => false
    end
    
    assert_not_equal RestParameter.last.name, "UNIQUE_TO_METHOD_#{method.id}-#{param_name}"
  end
  
  # ========================================
  
  
  private
  
  def login_and_create_service_with_endpoints(endpoint="")
    user = Factory.create(:user)
    do_login_for_functional_test(user)
    
    return create_rest_service(:submitter => user, :endpoints => endpoint)
  end
end
