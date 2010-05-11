require 'test_helper'

class RestResourceTest < ActiveSupport::TestCase
  def test_create_invalid
    res = RestResource.new().save
    assert !res
  end

  def test_check_duplicate
    rest_one = create_rest_service(:name => "one", :endpoints => "/resource.xml")
    assert_not_nil RestResource.check_duplicate(rest_one, "/resource.xml") # exists
    
    rest_two = create_rest_service(:name => "two", :endpoints => "/{id}?name=johndoe")
    assert_not_nil RestResource.check_duplicate(rest_two, "/{id}?name=johndoe") # exists
    
    rest_three = create_rest_service(:name => "three", :endpoints => "?xml=true&id={3}&method=getTag")
    assert_not_nil RestResource.check_duplicate(rest_three, "/?xml=true&method=getTag") # exists
    
    rest_one.destroy
    rest_two.destroy
    rest_three.destroy
  end
  
  def test_submitter
    user = Factory.create(:user)
    rest_service = create_rest_service(:endpoints => "/resource.xml")
    
    assert_not_equal rest_service.rest_resources[0].submitter, user # different users
    assert_not_nil rest_service.rest_resources[0].submitter

    rest_service.destroy
  end
  
  def test_add_methods
    rest = create_rest_service(:endpoints => "/{id}\n put /{id}?xml={true}\n PUt /{id}")
    
    added_methods = []
    rest.rest_resources[0].rest_methods.each { |x| added_methods << x.method_type }
    added_methods.sort!
    
    assert_equal 1, rest.rest_resources.size # only one rest_resource ie "/{id}"
    assert_equal 2, rest.rest_resources[0].rest_methods.size # only GET and PUT methods since PUT is repeated
    assert_equal added_methods, %w{ GET PUT }.sort
    
    rest.destroy
  end
end
