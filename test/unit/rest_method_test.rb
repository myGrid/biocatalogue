require 'test_helper'

class RestMethodTest < ActiveSupport::TestCase
  def test_create_invalid
    meth = RestMethod.new().save
    assert !meth
  end

  def test_check_duplicate
    rest = create_rest_service(:endpoints => "/people?name=doe")
    
    assert_not_nil RestMethod.check_duplicate(rest.rest_resources[0], "GET")
    assert_nil RestMethod.check_duplicate(rest.rest_resources[0], "PUT")
  end
  
  def test_submitter
    user = Factory.create(:user)
    rest_service = create_rest_service(:endpoints => "/resource.xml", :submitter => user)
    
    assert_equal rest_service.rest_resources[0].rest_methods[0].submitter, user # same submitter
  end

  def test_create_endpoint_with_no_params
    rest = create_rest_service(:endpoints => "/search")
    assert rest.rest_resources[0].rest_methods[0].request_parameters.empty?
  end
  
  def test_create_endpoint_with_multiple_params
    rest_none = create_rest_service(:endpoints => "/search")
    assert rest_none.rest_resources[0].rest_methods[0].request_parameters.empty?
    
    rest_one = create_rest_service(:endpoints => "/search?q={term}")
    assert_equal 1, rest_one.rest_resources[0].rest_methods[0].request_parameters.size    
    
    rest_two = create_rest_service(:endpoints => "/{api-v}/search.xml?q={term}")
    assert_equal 2, rest_two.rest_resources[0].rest_methods[0].request_parameters.size    
  end
  
  def test_add_parameters
    rest = create_rest_service(:endpoints => "/search?q={term}")
    method = rest.rest_resources[0].rest_methods[0]
        
    method.add_parameters("update=true", nil)
    assert_equal 1, method.request_parameters.size # should not add for nil user
    
    method.add_parameters("", Factory(:user))
    assert_equal 1, method.request_parameters.size # params size does not change
    
    method.add_parameters("xml=false !", Factory(:user))
    assert_equal 2, method.request_parameters.size # should increase by 1
    
    method.add_parameters("name=john-doe\nupdate=true\nname !\nalias={jadefox} !", Factory(:user))
    assert_equal 5, method.request_parameters.size # should increase by 3
  end
  
  def test_add_representations
    rest = create_rest_service(:endpoints => "/search.xml")
    method = rest.rest_resources[0].rest_methods[0]
        
    assert_equal 1, method.rest_method_representations.size
    
    method.add_representations("application/xml", nil)
    assert_equal 1, method.rest_method_representations.size # should not add for nil user
    
    method.add_representations("xml", Factory(:user))
    assert_equal 1, method.rest_method_representations.size # size does not change
    
    method.add_representations("application/xml", Factory(:user), :http_cycle => "request")
    assert_equal 1, method.rest_method_representations.size # should reuse existing
  end
end
