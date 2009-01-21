require File.dirname(__FILE__) + '/test_helper.rb'

class ConfigTest < Test::Unit::TestCase
  def setup
    Annotations::Config.attribute_names_for_values_to_be_downcased = [ "downcased_thing" ]
    Annotations::Config.attribute_names_for_values_to_be_upcased = [ "upcased_thing" ]
    Annotations::Config.strip_text_rules = { "tag" => [ '"', ',' ], "comma_stripped" => ',', "regex_strip" => /\d/ }
  end
  
  def teardown
    Annotations::Config.attribute_names_for_values_to_be_downcased = [ ]
    Annotations::Config.attribute_names_for_values_to_be_upcased = [ "upcased_thing" ]
    Annotations::Config.strip_text_rules = { }
  end
  
  def test_values_downcased_or_upcased
    source = users(:jane)
    
    # Should downcase

    ann1 = Annotation.create(:attribute_name => "downcased_thing", 
                            :value => "UNIque", 
                            :source_type => source.class.name, 
                            :source_id => source.id,
                            :annotatable_type => "Book",
                            :annotatable_id => 1)
    
    assert_valid ann1
    assert_equal "unique", ann1.value
    
    # Should upcase
    
    ann2 = Annotation.create(:attribute_name => "upcased_thing", 
                            :value => "UNIque", 
                            :source_type => source.class.name, 
                            :source_id => source.id,
                            :annotatable_type => "Book",
                            :annotatable_id => 1)
    
    assert_valid ann2
    assert_equal "UNIQUE", ann2.value
    
    # Should not do anything
    
    ann3 = Annotation.create(:attribute_name => "dont_do_anything", 
                            :value => "UNIque", 
                            :source_type => source.class.name, 
                            :source_id => source.id,
                            :annotatable_type => "Book",
                            :annotatable_id => 1)
    
    assert_valid ann3
    assert_equal "UNIque", ann3.value
  end
  
  def test_strip_text_rules
    source = users(:john)
    
    # Strip 'tag'
    
    ann1 = Annotation.create(:attribute_name => "Tag", 
                            :value => 'v,al"ue', 
                            :source_type => source.class.name, 
                            :source_id => source.id,
                            :annotatable_type => "Book",
                            :annotatable_id => 1)
    
    assert_valid ann1
    assert_equal "value", ann1.value
    
    # Strip 'comma_stripped'
    
    ann2 = Annotation.create(:attribute_name => "comma_stripped", 
                            :value => 'v,al"ue', 
                            :source_type => source.class.name, 
                            :source_id => source.id,
                            :annotatable_type => "Book",
                            :annotatable_id => 1)
    
    assert_valid ann2
    assert_equal 'val"ue', ann2.value
    
    # Regexp strip

    ann3 = Annotation.create(:attribute_name => "regex_strip", 
                            :value => 'v1,al"ue23x4', 
                            :source_type => source.class.name, 
                            :source_id => source.id,
                            :annotatable_type => "Book",
                            :annotatable_id => 1)
    
    assert_valid ann3
    assert_equal 'v,al"uex', ann3.value

    # Don't strip!
    
    ann4 = Annotation.create(:attribute_name => "dont_strip", 
                            :value => 'v,al"ue', 
                            :source_type => source.class.name, 
                            :source_id => source.id,
                            :annotatable_type => "Book",
                            :annotatable_id => 1)
    
    assert_valid ann4
    assert_equal 'v,al"ue', ann4.value
  end
end