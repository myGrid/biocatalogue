require File.dirname(__FILE__) + '/test_helper.rb'

class ActsAsFavouriterTest < Test::Unit::TestCase
  
  def test_has_many_favourites_association
    assert_equal 6, users(:jane).favourites.length
    assert_equal 4, users(:john).favourites.length
  end
  
  def test_find_favourites_by_class_method
    assert_equal 6, User.find_favourites_by(users(:jane).id).length
    assert_equal 4, User.find_favourites_by(users(:john).id).length
  end
  
  def test_latest_favourites_instance_method
    assert_equal 6, users(:jane).latest_favourites.length
    
    assert_equal 2, users(:john).latest_favourites(2).length
  end
  
  def test_favourited_items_instance_method
    assert_equal 6, users(:jane).favourited_items.length
    assert_equal 4, users(:john).favourited_items.length 
  end
  
end