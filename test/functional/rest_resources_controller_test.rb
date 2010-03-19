require 'test_helper'

class RestResourcesControllerTest < ActionController::TestCase
  test "get something without logging in" do
    get :new_popup
    assert_redirected_to :login
    
    get :add_new_resources
    assert_redirected_to :login
  end

  test "get new popup" do
    do_login_for_functional_test
    
    get :new_popup, :rest_service_id => create_rest_service.id
    assert_response :success
  end
  
  test "add new resources" do
    user = Factory.create(:user)
    do_login_for_functional_test(user)
    
    assert_difference('RestResource.count', 3) do 
      post :add_new_resources, :rest_resources => "/res.xml \n /{id} \n ?id={id}&meth=getPics", 
           :rest_service_id => create_rest_service(:submitter => user).id
    end
    
    assert_redirected_to (service_path(Service.last) + "#endpoints")
  end
  
  test "add one new resource" do
    user = Factory.create(:user)
    do_login_for_functional_test(user)
    
    assert_difference('RestResource.count', 1) do 
      post :add_new_resources, :rest_resources => "/res.xml", 
           :rest_service_id => create_rest_service(:submitter => user).id
    end
    
    assert_redirected_to (service_path(Service.last) + "#endpoints")
  end
end
