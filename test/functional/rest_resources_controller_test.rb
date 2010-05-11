require 'test_helper'

class RestResourcesControllerTest < ActionController::TestCase
  def test_get_page_without_logging_in
    get :new_popup
    assert_redirected_to :login
    
    get :add_new_resources
    assert_redirected_to :login
  end

  def test_get_new_popup
    do_login_for_functional_test
    
    get :new_popup, :rest_service_id => create_rest_service.id
    assert !flash[:error].blank?
  end
  
  # THE TEST BELOW ARE CURRENTLY NOT WORKING
  # TODO: fix tests for add new resources
  def add_new_resources 
    user = Factory.create(:user)
    do_login_for_functional_test(user)

    env["HTTP_REFERER"] = "/rest_methods/"
    
    assert_difference('RestResource.count', 3) do 
      post :add_new_resources, :rest_resources => "/res.xml \n /{id} \n ?id={id}&meth=getPics", 
                               :rest_service_id => create_rest_service(:submitter => user).id
    end
    
    assert_redirected_to (service_path(Service.last) + "#endpoints")
  end
  
  def add_one_new_resource
    user = Factory.create(:user)
    do_login_for_functional_test(user)
    
    assert_difference('RestResource.count', 1) do 
      post :add_new_resources, :rest_resources => "/res.xml", 
           :rest_service_id => create_rest_service(:submitter => user).id
    end
    
    assert_redirected_to (service_path(Service.last) + "#endpoints")
  end
end
