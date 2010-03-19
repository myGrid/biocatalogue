require 'test_helper'

class RestServicesControllerTest < ActionController::TestCase
  BASE_ENDPOINT = "http://www.my-service.com/api/v1"
  ONE_URL = "DELete  www.my-service.com/api/v1/format.xml?id=3&name=johndoe"
  TWO_URLS = "www.my-service.com/api/v1?id=3&method=getSomething\r\nDELete  www.my-service.com/api/v1/format.xml?id=3&name=johndoe"
  
  test "should ask for login" do
    get :new
    assert_redirected_to :login
  end

  test "create rest_service with one endpoint" do
    do_login_for_functional_test
    
    assert_difference('RestService.count') do
      post :create, :endpoint => BASE_ENDPOINT, 
                    :rest_service => {:name => "test"},
                    :annotations => {},
                    :rest_resources => ONE_URL
    end

    assert_redirected_to service_path(RestService.last.service)
  end

  test "create rest_service with multiple endpoints" do
    do_login_for_functional_test
    
    assert_difference('RestService.count') do
      post :create, :endpoint => BASE_ENDPOINT, 
                    :rest_service => {:name => "test"},
                    :annotations => {},
                    :rest_resources => TWO_URLS
    end
    
    assert_redirected_to service_path(RestService.last.service)
  end

  test "create rest_service with no endpoints" do
    do_login_for_functional_test
    
    assert_difference('RestService.count') do
      post :create, :endpoint => BASE_ENDPOINT, 
                    :rest_service => {:name => "test"},
                    :annotations => {},
                    :rest_resources => ""
    end
  
    assert_redirected_to service_path(RestService.last.service)
  end
  
  test "attempt to create rest_service that exists and redirect" do
    do_login_for_functional_test
    
    assert_difference('RestService.count') do
      post :create, :endpoint => BASE_ENDPOINT, 
                    :rest_service => {:name => "test"},
                    :annotations => {},
                    :rest_resources => ""
    end
    
    assert_difference('RestService.count', 0) do
      post :create, :endpoint => BASE_ENDPOINT, 
                    :rest_service => {:name => "test"},
                    :annotations => {},
                    :rest_resources => ""
                    
    assert_redirected_to service_path(RestService.last.service)
    end
  end
  
  test "attempt update base endpoint without logging in" do
    get :edit_base_endpoint_by_popup
    assert_redirected_to :login
    
    get :update_base_endpoint
    assert_redirected_to :login
  end
  
  test "update base endpoint" do
    do_login_for_functional_test

    post :create, :endpoint => BASE_ENDPOINT, 
                  :rest_service => {:name => "test"},
                  :annotations => {},
                  :rest_resources => ""
    
    # Does not change
    post :update_base_endpoint, :service_deployment_id => ServiceDeployment.find_by_endpoint(BASE_ENDPOINT).id,
                                :new_endpoint => BASE_ENDPOINT+'/'
    assert_not_nil ServiceDeployment.find_by_endpoint(BASE_ENDPOINT)
    assert_nil ServiceDeployment.find_by_endpoint(BASE_ENDPOINT+'/')

    # Changes
    post :update_base_endpoint, :service_deployment_id => ServiceDeployment.find_by_endpoint(BASE_ENDPOINT).id,
                                :new_endpoint => BASE_ENDPOINT+'/changed'
    assert_nil ServiceDeployment.find_by_endpoint(BASE_ENDPOINT)
    assert_not_nil ServiceDeployment.find_by_endpoint(BASE_ENDPOINT+'/changed')
  end
end
