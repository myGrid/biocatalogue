require 'test_helper'

class RestServiceTest < ActiveSupport::TestCase
  BASE_ENDPOINT = "http://www.my-service.com/api/v1/"
  
  ONE_URL = "DELete  www.my-service.com/api/v1/format.xml?id=3&name=johndoe"
  ONE_URL_TWICE = ONE_URL + "\r\n" + ONE_URL
  TWO_URLS = "www.my-service.com/api/v1?id=3&method=getSomething\r\nDELete  www.my-service.com/api/v1/format.xml?id=3&name=johndoe"
  TWO_URLS_ONE_REPEATED = TWO_URLS + "\r\n" + ONE_URL
  
  
  # ========================================
  
  
  def test_create_rest_service_without_user
    rest_service = create_rest_service(:submitter => nil)
    assert_nil rest_service.service # was not submitted
  end

  def test_create_rest_service_without_endpoints
    rest_service = create_rest_service
    
    assert_not_nil rest_service.service # submitted
    assert_not_nil rest_service.service.submitter # has submitter
    assert rest_service.rest_resources.empty? # has no rest_resources
  end
    
  def test_method_mine_for_resources_same_submitter
    submitter = Factory.create(:user)
    rest_service = create_rest_service(:submitter => submitter)
    
    rest_service.mine_for_resources("", BASE_ENDPOINT.clone, submitter)
    assert rest_service.rest_resources.empty? # no resources should have been added
    
    rest_service.mine_for_resources(ONE_URL_TWICE.clone, BASE_ENDPOINT.clone, submitter)
    assert_equal 1, rest_service.rest_resources.size # 1 resource added
    
    assert_equal submitter, rest_service.rest_resources.first.submitter # same submitter
  end
  
  def test_method_mine_for_resources_different_submitters
    diff_submitter = Factory.create(:user)
    rest_service = create_rest_service
    
    rest_service.mine_for_resources(TWO_URLS.clone, BASE_ENDPOINT.clone, diff_submitter)
    assert_equal 2, rest_service.rest_resources.size # 1 more resource added
    
    sub_one = rest_service.service.submitter
    sub_two = rest_service.rest_resources[0].submitter
    
    assert_not_equal sub_one, sub_two # not the same submitter
  end
end
