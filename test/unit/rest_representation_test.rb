require 'test_helper'

class RestRepresentationTest < ActiveSupport::TestCase
  def test_create_invalid
    param = RestRepresentation.new().save
    assert !param
  end

  def test_representation_count
    rest = create_rest_service(:endpoints => "/results.xml")
    assert_equal RestRepresentation.count, 0
  end

  def test_check_duplicate
    rest = create_rest_service(:endpoints => "/workflows.xml")
    
    method = rest.rest_resources[0].rest_methods[0]
    method.add_representations("application/xml", rest.service.submitter)
    
    assert_nil RestRepresentation.check_duplicate(method, "xml") # does not exist
    assert_nil RestRepresentation.check_duplicate(method, "application/xml", "request") # does not exist
    assert_not_nil RestRepresentation.check_duplicate(method, "application/xml", "response") # exists
    assert_not_nil RestRepresentation.check_duplicate(method, "application/xml") # exists
  end
    
  def test_check_exists_for_rest_service
    rest = create_rest_service(:endpoints => "/workflows.xml")

    method = rest.rest_resources[0].rest_methods[0]
    method.add_representations("application/xml", rest.service.submitter)
    
    assert_nil RestRepresentation.check_exists_for_rest_service(rest, "xml") # does not exist
    assert_not_nil RestRepresentation.check_exists_for_rest_service(rest, "application/xml") # exists
  end
  
  def test_submitter
    submitter = Factory.create(:user)
    
    rest = create_rest_service(:endpoints => "/{id}", :submitter => submitter)
    method = rest.rest_resources[0].rest_methods[0]
    method.add_representations("application/xml", submitter)
    rep = method.rest_method_representations(true)[0]
    
    assert_equal rep.submitter, submitter # the submitter
  end
end
