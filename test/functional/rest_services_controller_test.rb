require 'test_helper'

class RestServicesControllerTest < ActionController::TestCase
  BASE_ENDPOINT = "http://www.my-service.com/api/"
  ONE_ENDPOINT = "DELete  www.my-service.com/api/{api-v}/people.{format}?id={id}&name=x{}"
  TWO_ENDPOINTS = "www.my-service.com/api/{api-v}?id={x}&method=getPerson\r\n#{ONE_ENDPOINT}"
    
  def test_register_service_without_authentication
    get :new
    assert_redirected_to :login
  end

  def test_register_service
    do_login_for_functional_test
    
    assert_difference('RestService.count') do
      post :create, :endpoint => BASE_ENDPOINT, 
                    :rest_service => {:name => "test"},
                    :annotations => {}
    end
  
    assert_redirected_to service_path(RestService.last.service)
  end
  
  def test_register_existing_service
    do_login_for_functional_test
    
    assert_difference('RestService.count', 1) do
      post :create, :endpoint => BASE_ENDPOINT, 
                    :rest_service => {:name => "test 1"},
                    :annotations => {}
    end
    
    assert_difference('RestService.count', 0) do
      post :create, :endpoint => BASE_ENDPOINT, 
                    :rest_service => {:name => "test 2"},
                    :annotations => {}
                    
      assert_redirected_to service_path(RestService.last.service)
    end
  end

  def test_update_base_endpoint_without_authentication
    get :edit_base_endpoint_by_popup
    assert_redirected_to :login
    
    get :update_base_endpoint
    assert_redirected_to :login
  end
  
  def test_unauthorised_update_base_endpoint
    #do_login_for_functional_test
    #
    #base = BASE_ENDPOINT + "/new_version"
    #
    #post :create, :endpoint => base,
    #              :rest_service => {:name => "test 1"},
    #              :annotations => {}

    service_deployment = service_deployments(:cinemaquery_deployment1)
    base = service_deployment.endpoint
    
    do_login_for_functional_test # login as a different user
    
    post :update_base_endpoint, :service_deployment_id => service_deployment.id,
                                :new_endpoint => base + '/changed'
    
    assert_nil ServiceDeployment.find_by_endpoint(base + '/changed')
    assert_not_nil ServiceDeployment.find_by_endpoint(base)
  end
  
  def test_update_base_endpoint
    do_login_for_functional_test
    
    base = BASE_ENDPOINT + "/different_version"
    
    post :create, :endpoint => base, 
                  :rest_service => {:name => "test"},
                  :annotations => {}
    
    # Does not change
    post :update_base_endpoint, :service_deployment_id => ServiceDeployment.find_by_endpoint(base).id,
                                :new_endpoint => base + '/'
    assert_not_nil ServiceDeployment.find_by_endpoint(base)
    assert_nil ServiceDeployment.find_by_endpoint(base + '/') # should not store with trailing '/'

    # Changes
    post :update_base_endpoint, :service_deployment_id => ServiceDeployment.find_by_endpoint(base).id,
                                :new_endpoint => base + '/changed'
    assert_nil ServiceDeployment.find_by_endpoint(base)
    assert_not_nil ServiceDeployment.find_by_endpoint(base + '/changed')
  end

end
