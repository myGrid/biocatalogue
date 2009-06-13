require File.dirname(__FILE__) + '/test_helper.rb'

class AnnotationVersionTest < ActiveSupport::TestCase
  
  def test_annotation_version_class_loaded
    assert_kind_of Annotation::Version, Annotation::Version.new
  end
  
  def test_versioning_on_update
    ann = annotations(:bh_title_1)
    
    # Check number of versions
    assert_equal 1, ann.versions.length
    
    # Update the value and check that a version has been created
    
    ann.value = "Harry Potter IIIIIII"
    ann.version_creator = users(:john)

    assert ann.valid?
    
    assert ann.save
    
    assert_equal 2, ann.versions.length
    assert_equal "Harry Potter IIIIIII", ann.value
    assert_equal "Harry Potter IIIIIII", ann.versions.latest.value
    assert_equal "Harry Potter and the Exploding Men's Locker Room", ann.versions.latest.previous.value
    assert_equal users(:john).id, ann.version_creator_id
    assert_equal users(:john).id, ann.versions.latest.version_creator_id
    assert_equal nil, ann.versions.latest.previous.version_creator_id
  end
  
end