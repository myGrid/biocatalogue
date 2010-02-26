require 'test_helper'

class RestServicesControllerTest < ActionController::TestCase
  BASE_ENDPOINT = "http://www.my-service.com/api/v1"
  ONE_URL = "DELete  www.my-service.com/api/v1/format.xml?id=3&name=johndoe"
  TWO_URLS = "www.my-service.com/api/v1?id=3&method=getSomething\r\nDELete  www.my-service.com/api/v1/format.xml?id=3&name=johndoe"
  
  test "should ask for login" do
    get :new
    assert_redirected_to :login
  end

  test "should create rest_service with one endpoint" do
    do_login_for_functional_test
    
    assert_difference('RestService.count') do
      post :create, :endpoint => BASE_ENDPOINT, 
                    :rest_service => {:name => "test"},
                    :annotations => {},
                    :rest_resources => ONE_URL
    end
    
#    path = "/services/#{RestService.last.service.id}-test_"
#    assert service_path(RestService.last.service).include? path

    assert_redirected_to service_path(RestService.last.service)
  end

  test "should create rest_service with multiple endpoints" do
    do_login_for_functional_test
    
    assert_difference('RestService.count') do
      post :create, :endpoint => BASE_ENDPOINT, 
                    :rest_service => {:name => "test"},
                    :annotations => {},
                    :rest_resources => TWO_URLS
    end
    
    assert_redirected_to service_path(RestService.last.service)
  end

  test "should create rest_service with no endpoints" do
    do_login_for_functional_test
    
    assert_difference('RestService.count') do
      post :create, :endpoint => BASE_ENDPOINT, 
                    :rest_service => {:name => "test"},
                    :annotations => {},
                    :rest_resources => ""
    end
  
    assert_redirected_to service_path(RestService.last.service)
  end
  
  test "should create rest_service that exists" do
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
    end
  end
  
end
