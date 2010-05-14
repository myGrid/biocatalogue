require 'test_helper'

class RestParameterTest < ActiveSupport::TestCase  
  def test_create_invalid
    param = RestParameter.new().save
    assert !param
  end

  def test_parameter_count
    rest_one = create_rest_service(:endpoints => "/search?q={term}&style=raw")
    rest_two = create_rest_service(:endpoints => "/{db}/{id}")
    
    assert_equal RestParameter.count, 3
    
    rest_one.service.destroy
    rest_two.service.destroy
  end

  def test_check_duplicate
    rest = create_rest_service(:endpoints => "/workflows.xml?xml={true}")
    method = rest.rest_resources[0].rest_methods[0]
    
    assert_nil RestParameter.check_duplicate(method, "id") # global ID does not exist
    assert_nil RestParameter.check_duplicate(method, "xml") # global XML does not exist
    
    assert_nil RestParameter.check_duplicate(method, "id", true) # local id does not exist
    assert_not_nil RestParameter.check_duplicate(method, "xml", true) # local XML exists
    
    rest.service.destroy
  end
    
  def test_check_exists_for_rest_service
    rest = create_rest_service(:endpoints => "/workflows.xml?xml={true}")
    method = rest.rest_resources[0].rest_methods[0]
    
    assert_nil RestParameter.check_exists_for_rest_service(rest, "id") # global ID does not exist
    assert_nil RestParameter.check_exists_for_rest_service(rest, "xml") # global XML does not exist
            
    assert_nil RestParameter.check_exists_for_rest_service(rest, "id", true) # local ID does not exist
    assert_not_nil RestParameter.check_exists_for_rest_service(rest, "xml", true) # local XML exists    
    
    rest.service.destroy
  end
  
  def test_submitter
    submitter = Factory.create(:user)
    
    rest = create_rest_service(:endpoints => "/{id}", :submitter => submitter)
    param = rest.rest_resources[0].rest_methods[0].request_parameters[0]
    
    assert_equal param.submitter, submitter # the submitter
    
    rest.service.destroy
  end
end
