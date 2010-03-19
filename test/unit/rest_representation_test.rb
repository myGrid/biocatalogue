require 'test_helper'

class RestRepresentationTest < ActiveSupport::TestCase
  def test_create_invalid
    param = RestRepresentation.new().save
    assert !param
  end

  def test_parameter_count
    rest_one = create_rest_service(:endpoints => "/results.xml")
    assert_equal RestRepresentation.count, 1
    
    rest_two = create_rest_service(:endpoints => "/{db}/{id}.json")
    assert_equal RestRepresentation.count, 2
  end

  def test_check_duplicate
    rest = create_rest_service(:endpoints => "/workflows.xml")
    method = rest.rest_resources[0].rest_methods[0]
    
    assert_nil RestRepresentation.check_duplicate(method, "xml") # does not exist
    assert_nil RestRepresentation.check_duplicate(method, "application/xml", "request") # does not exist
    assert_not_nil RestRepresentation.check_duplicate(method, "application/xml", "response") # exists
    assert_not_nil RestRepresentation.check_duplicate(method, "application/xml") # exists
  end
    
  def test_check_exists_for_rest_service
    rest = create_rest_service(:endpoints => "/workflows.xml")
    method = rest.rest_resources[0].rest_methods[0]
    
    assert_nil RestRepresentation.check_exists_for_rest_service(rest, "xml") # does not exist
    assert_not_nil RestRepresentation.check_exists_for_rest_service(rest, "application/xml") # exists
  end
  
  def test_submitter
    submitter = Factory.create(:user)
    
    rest = create_rest_service(:endpoints => "/{id}.xml", :submitter => submitter)
    rep = rest.rest_resources[0].rest_methods[0].rest_method_representations[0]
    
    assert_equal rep.submitter, submitter # the submitter
  end
end
