require 'test_helper'

class RestMethodRepresentationTest < ActiveSupport::TestCase
  def test_create_invalid
    map = RestMethodRepresentation.new().save
    assert !map
  end
  
  def test_submitter
    rest = create_rest_service(:endpoints => "/workflow.xml")
    method = rest.rest_resources[0].rest_methods[0]
    map = method.rest_method_representations[0]
    
    assert_not_nil method.submitter # should have a submitter
    assert_equal method.submitter, map.submitter # same submitter
  end
  
  def test_linking
    rest = create_rest_service(:endpoints => "/workflow.rdf")    
    method = rest.rest_resources[0].rest_methods[0]
    map = method.rest_method_representations[0]
    rep = method.response_representations[0]
    
    assert_equal map.rest_method_id, RestMethod.first.id
    assert_equal map.rest_representation_id, RestRepresentation.first.id
    assert_equal rep, RestRepresentation.first
  end
end
