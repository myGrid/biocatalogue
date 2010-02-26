require 'test_helper'

class RestMethodParameterTest < ActiveSupport::TestCase
  def test_links_and_submitter
    rest = create_rest_service(:endpoints => "/3")
    method = rest.rest_resources[0].rest_methods[0]
    map = method.rest_method_parameters[0]
    
    assert_not_nil method.submitter # should have a submitter
    assert_equal method.submitter, map.submitter # same submitter
    
    assert_equal map.rest_method_id, RestMethod.first.id
    assert_equal map.rest_parameter_id, RestParameter.first.id
  end
end
