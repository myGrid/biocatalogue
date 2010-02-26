require 'test_helper'

class RestMethodTest < ActiveSupport::TestCase

  def test_check_duplicate
    rest = create_rest_service(:endpoints => "/3?name=doe")
    
    assert_not_nil RestMethod.check_duplicate(rest.rest_resources[0], "GET")
    assert_nil RestMethod.check_duplicate(rest.rest_resources[0], "PUT")
  end
  
  def test_submitter
    user = Factory.create(:user)
    rest_service = create_rest_service(:endpoints => "/resource.xml", :submitter => user)
    
    assert_equal rest_service.rest_resources[0].rest_methods[0].submitter, user # same submitter
  end

  def test_add_parameters
    rest = create_rest_service(:endpoints => "put /3")
    method = rest.rest_resources[0].rest_methods[0]
    
    assert_equal 1, method.request_parameters.size # should have one param ("id")
    
    method.add_parameters("update=true", nil)
    assert_equal 1, method.request_parameters.size # should not add for nil user
    
    method.add_parameters("", Factory(:user))
    assert_equal 1, method.request_parameters.size # params size does not change
    
    method.add_parameters("xml=false", Factory(:user))
    assert_equal 2, method.request_parameters.size # should increase by 1
    
    method.add_parameters("name=john-doe\nupdate=true\nname=jadefox", Factory(:user))
    assert_equal 4, method.request_parameters.size # should increase by 2
  end
end
