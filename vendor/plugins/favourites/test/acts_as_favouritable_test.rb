require File.dirname(__FILE__) + '/test_helper.rb'

class ActsAsFavouritableTest < Test::Unit::TestCase
  
  def test_has_many_favourites_association
    assert_equal 1, books(:s).favourites.length
    assert_equal 2, chapters(:bh_c1).favourites.length
    assert_equal 0, chapters(:br_c202).favourites.length
  end
  
  def test_find_favourites_for_class_method
    assert_equal 1, Book.find_favourites_for(books(:s).id).length
    assert_equal 2, Chapter.find_favourites_for(chapters(:bh_c1).id).length
    assert_equal 0, Chapter.find_favourites_for(chapters(:br_c202).id).length
  end
  
  def test_find_favourites_by_class_method
    assert_equal 4, Book.find_favourites_by(users(:jane).id).length
    assert_equal 2, Chapter.find_favourites_by(users(:john).id).length
  end
  
  def test_favouritable_name_instance_method
    assert_equal "Sorry, Did I Say 2 Seconds? I Meant 2 Years!", chapters(:br_c202).favouritable_name
    assert_equal "Crazy Frogs In Summer", books(:f).favouritable_name
  end
  
  def test_latest_favourites_instance_method
    assert_equal 2, books(:h).latest_favourites.length
    assert_equal 1, chapters(:bh_c10).latest_favourites.length
    
    assert_equal 1, books(:h).latest_favourites(1).length
  end
  
  def test_favourited_by_user_instance_method
    assert_equal true, books(:h).favourited_by_user?(users(:jane).id)
    assert_equal false, chapters(:bh_c10).favourited_by_user?(users(:john).id)
    assert_equal false, chapters(:br_c202).favourited_by_user?(users(:jane).id)
  end
  
end