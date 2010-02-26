require 'test_helper'

class AnnotationTest < ActiveSupport::TestCase
  
  def test_display_name_annotations
    
    service1 = services(:cinemaquery)
    service2 = services(:shopping_service)
    
    
    a1 = Annotation.create(:attribute_name => "alternative_name",
                           :source => users(:john),
                           :annotatable => service1,
                           :value => "My Alternative Name 1")
    
    assert a1.valid?, "Tried to create a new Annotation but it was invalid"
    assert_not_nil a1, "Tried to create a new Annotation but it became nil"
    
    assert_equal 1, service1.annotations.length, "Too many annotations for this Service!"
    
    
    a2 = Annotation.create(:attribute_name => "display_name",
                           :source => users(:john),
                           :annotatable => service1,
                           :value => "My Display Name 1")
    
    assert_equal 2, service1.annotations(true).length, "Too many annotations for this Service!"
    
    
    a3 = Annotation.create(:attribute_name => "display_name",
                           :source => users(:john),
                           :annotatable => service2,
                           :value => "My Display Name")
    
    assert a1.valid?, "Tried to create a new Annotation but it was invalid"
    assert_not_nil a1, "Tried to create a new Annotation but it became nil"
    
    assert_equal 1, service2.annotations.length, "Too many annotations for this Service!"
    
    
    a4 = Annotation.create(:attribute_name => "display_name",
                           :source => users(:john),
                           :annotatable => service1,
                           :value => "My Display Name 2")
    
    assert a4.valid?, "Tried to create a new Annotation but it was invalid"
    assert_not_nil a4, "Tried to create a new Annotation but it became nil"
    
    assert_equal "alternative_name", a2.reload.attribute_name
    
    assert_equal 3, service1.annotations(true).length, "Too many annotations for this Service!"
    
  end

end
