require 'test_helper'

class RestMethodRepresentationTest < ActiveSupport::TestCase
  def test_create_invalid
    map = RestMethodRepresentation.new().save
    assert !map
  end
  
  def test_submitter
    rest = create_rest_service(:endpoints => "/workflow.xml")
    method = rest.rest_resources[0].rest_methods[0]
    
    assert_not_nil method.submitter # should have a submitter
    assert_equal method.submitter, rest.service.submitter # same submitter

    rest.service.destroy
  end
  
  def test_linking
    rest = create_rest_service(:endpoints => "/workflow.rdf")    
    method = rest.rest_resources[0].rest_methods[0]
    
    assert_nil method.rest_method_representations[0]
    assert_nil method.response_representations[0]
    
    method.add_representations("application/rdf", rest.service.submitter)
    
    assert_not_nil method.response_representations(true)[0]
    assert_equal method.response_representations(true)[0], RestRepresentation.last

    rest.service.destroy
  end
end
