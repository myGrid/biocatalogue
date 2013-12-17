require File.dirname(__FILE__) + '/test_helper.rb'

class FavouriteTest < ActiveSupport::TestCase
  
  def test_favourite_class_loaded
    assert_kind_of Favourite, Favourite.new
  end
  
  def test_fixtures_loaded
    assert_equal 4, Book.count(:all)
    assert_equal 4, Chapter.count(:all)
    assert_equal 2, User.count(:all)
    assert_equal 10, Favourite.count(:all)
    
    assert_equal 1, books(:h).id
    assert_equal 2, chapters(:bh_c10).id
    assert_equal 2, users(:jane).id
  end
  
  def test_belongs_to_favouritable_association
    assert_equal books(:h), Favourite.find(4).favouritable
    assert_equal chapters(:bh_c10), Favourite.find(2).favouritable
  end
  
  def test_belongs_to_user_association
    assert_equal users(:john), Favourite.find(7).user
    assert_equal users(:jane), Favourite.find(9).user
  end
  
  def test_for_favouritable_scope_finder
    assert_equal 2, Favourite.for_favouritable('Book', books(:h).id).length
    assert_equal 1, Favourite.for_favouritable('Chapter', chapters(:bh_c10).id).length
    assert_equal 0, Favourite.for_favouritable('Chapter', chapters(:br_c202).id).length
  end
  
  def test_by_user_scope_finder
    assert_equal 6, Favourite.by_user(users(:jane).id).length
    assert_equal 4, Favourite.by_user(users(:john).id).length
  end
  
  def test_find_favouritable_class_method
    assert_equal books(:h), Favourite.find_favouritable('Book', books(:h).id)
    assert_equal chapters(:br_c2), Favourite.find_favouritable('Chapter', chapters(:br_c2).id)
  end
  
  def test_create_favourite
    favouritable = chapters(:br_c202)
    
    user1 = users(:john)
    
    f1 = Favourite.new
    f1.favouritable = favouritable
    f1.user = user1
    assert f1.save
    
    user2 = users(:jane)
    
    f2 = Favourite.create(:favouritable_type => 'Chapter',
                          :favouritable_id => favouritable.id,
                          :user_id => user2.id)  
    assert f2.valid?
  end
  
  def test_cannot_create_favourite_with_invalid_favouritable
    f = Favourite.new(:favouritable_type => 'Book',
                      :favouritable_id => 450,
                      :user_id => users(:jane).id)
    assert_equal false, f.save
  end
  
  def test_cannot_create_duplicate_favourite
    # Shouldn't be able to create a favourite that has already been made...
    f = Favourite.new(:favouritable_type => 'Book',
                      :favouritable_id => books(:h).id,
                      :user_id => users(:jane).id)
    assert_equal false, f.save
  end
  
end