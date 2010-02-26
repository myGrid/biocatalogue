require 'test_helper'

class RestParameterTest < ActiveSupport::TestCase
  def test_one_parameter
    rest = create_rest_service(:endpoints => "/5")
    params = rest.rest_resources[0].rest_methods[0].request_parameters
    
    assert_equal 1, params.size
  end
  
  def test_multiple_parameters
    rest = create_rest_service(:endpoints => "/3?name=john+doe&xml=true&update=true")
    params = rest.rest_resources[0].rest_methods[0].request_parameters
    
    assert_equal 4, params.size    
  end
  
  def test_check_duplicate
    rest = create_rest_service(:endpoints => "/10")
    method = rest.rest_resources[0].rest_methods[0]
    
    assert_nil RestParameter.check_duplicate(method, "fake") # does not exist
    assert_not_nil RestParameter.check_duplicate(method, "id") # exists
  end
  
  def test_parameter_count
    rest_one = create_rest_service(:endpoints => "/10")
    rest_two = create_rest_service(:endpoints => "/3?name=john-doe")
    
    assert_equal RestParameter.count, 3
  end
  
  def test_check_exists_for_rest_service
    rest = create_rest_service(:endpoints => "/5")

    assert_nil RestParameter.check_exists_for_rest_service(rest, "non-existant") # does not exist
    assert_not_nil RestParameter.check_exists_for_rest_service(rest, "id") # exists
  end
  
  def test_submitter
    submitter = Factory.create(:user)
    
    rest = create_rest_service(:endpoints => "/23", :submitter => submitter)
    param = rest.rest_resources[0].rest_methods[0].request_parameters[0]
    
    assert_equal param.submitter, submitter # the submitter
  end
end
