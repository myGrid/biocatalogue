require 'test_helper'

class RestResourceTest < ActiveSupport::TestCase
  def test_check_duplicate
    rest_one = create_rest_service(:name => "one", :endpoints => "/resource.xml")
    assert_nil RestResource.check_duplicate(rest_one, "./") # does not exist
    assert_not_nil RestResource.check_duplicate(rest_one, "/resource.xml") # exists
    
    rest_two = create_rest_service(:name => "two", :endpoints => "/3?name=johndoe")
    assert_not_nil RestResource.check_duplicate(rest_two, "./") # exists
    assert_equal 1, rest_two.rest_resources.size
    
    rest_three = create_rest_service(:name => "three", :endpoints => "?id=3&method=getTag")
    assert_not_nil RestResource.check_duplicate(rest_three, ".") # exists
  end
  
  def test_submitter
    user = Factory.create(:user)
    rest_service = create_rest_service(:endpoints => "/resource.xml")
    
    assert_not_equal rest_service.rest_resources[0].submitter, user # different users
  end
  
  def test_add_methods
    rest = create_rest_service(:endpoints => "/3\n put /5\n PUt /2")
    
    added_methods = []    
    rest.rest_resources[0].rest_methods.each { |x| added_methods << x.method_type }
    added_methods.sort!
    
    assert_equal 1, rest.rest_resources.size # only one rest_resource ie "./"
    assert_equal 2, rest.rest_resources[0].rest_methods.size # only GET and PUT methods since PUT is repeated
    assert_equal added_methods, %w{ GET PUT }.sort
  end
end
