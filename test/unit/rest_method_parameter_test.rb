require 'test_helper'

class RestMethodParameterTest < ActiveSupport::TestCase
  def test_create_invalid
    map = RestMethodParameter.new().save
    assert !map
  end
  
  def test_submitter
    rest = create_rest_service(:endpoints => "/{id}")
    method = rest.rest_resources[0].rest_methods[0]
    map = method.rest_method_parameters[0]
    
    assert_not_nil method.submitter # should have a submitter
    assert_equal method.submitter, map.submitter # same submitter

    rest.service.destroy
  end
  
  def test_linking
    rest = create_rest_service(:endpoints => "/{id}")    
    map = rest.rest_resources[0].rest_methods[0].rest_method_parameters[0]
    
    assert_equal map.rest_method_id, RestMethod.first.id
    assert_equal map.rest_parameter_id, RestParameter.first.id

    rest.service.destroy
  end
end
