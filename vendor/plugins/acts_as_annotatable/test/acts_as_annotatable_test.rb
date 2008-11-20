require File.dirname(__FILE__) + '/test_helper.rb'

class ActsAsAnnotatableTest < Test::Unit::TestCase
  load_schema
  
  fixtures :books, :chapters
  
  def test_fixtures_loaded
    assert_equal 2, Book.all.length
    assert_equal 4, Chapter.all.length
    
    assert_equal 1, books(:harry_pooter).id
    assert_equal 2, chapters(:h_ch_10).id
  end
end
