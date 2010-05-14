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
  
  def add_new_resources # TODO: fix test env["HTTP_REFERER"] issue
    user = Factory.create(:user)
    do_login_for_functional_test(user)

    env["HTTP_REFERER"] = "/rest_methods/"
    rest = create_rest_service(:submitter => user)
    
    assert_difference('RestResource.count', 3) do 
      put :add_new_resources, 
          :rest_resources => "/res.xml \n /{id} \n ?id={id}&meth=getPics", 
          :rest_service_id => rest.id
    end
    
    assert_redirected_to (service_path(Service.last) + "#endpoints")
    rest.service.destroy
  end
  
  def unauthorised_add_new_resources # TODO: fix redirected_to :login issue
    do_login_for_functional_test
    rest = create_rest_service
    
    do_login_for_functional_test
                
    assert_difference('RestResource.count', 0) do 
      put :add_new_resources, 
          :rest_resources => "/res.xml", 
          :rest_service_id => rest.id
    end
    
    assert_redirected_to :login
    rest.service.destroy
  end
end
