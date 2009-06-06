require File.dirname(__FILE__) + '/test_helper.rb'

class ConfigTest < ActiveSupport::TestCase
  def setup
    Annotations::Config.attribute_names_for_values_to_be_downcased = [ "downcased_thing" ]
    Annotations::Config.attribute_names_for_values_to_be_upcased = [ "upcased_thing" ]
    Annotations::Config.strip_text_rules = { "tag" => [ '"', ',' ], "comma_stripped" => ',', "regex_strip" => /\d/ }
    Annotations::Config.limits_per_source = { "rating" => [ 1, true ] }
    Annotations::Config.attribute_names_to_allow_duplicates = [ "allow_duplicates_for_this" ]
  end
  
  def teardown
    Annotations::Config.attribute_names_for_values_to_be_downcased = [ ]
    Annotations::Config.attribute_names_for_values_to_be_upcased = [ ]
    Annotations::Config.strip_text_rules = { }
    Annotations::Config.limits_per_source = { }
    Annotations::Config.attribute_names_to_allow_duplicates = [ ]
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
    
    assert ann1.valid?
    assert_equal "unique", ann1.value
    
    # Should upcase
    
    ann2 = Annotation.create(:attribute_name => "upcased_thing", 
                            :value => "UNIque", 
                            :source_type => source.class.name, 
                            :source_id => source.id,
                            :annotatable_type => "Book",
                            :annotatable_id => 1)
    
    assert ann2.valid?
    assert_equal "UNIQUE", ann2.value
    
    # Should not do anything
    
    ann3 = Annotation.create(:attribute_name => "dont_do_anything", 
                            :value => "UNIque", 
                            :source_type => source.class.name, 
                            :source_id => source.id,
                            :annotatable_type => "Book",
                            :annotatable_id => 1)
    
    assert ann3.valid?
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
    
    assert ann1.valid?
    assert_equal "value", ann1.value
    
    # Strip 'comma_stripped'
    
    ann2 = Annotation.create(:attribute_name => "comma_stripped", 
                            :value => 'v,al"ue', 
                            :source_type => source.class.name, 
                            :source_id => source.id,
                            :annotatable_type => "Book",
                            :annotatable_id => 1)
    
    assert ann2.valid?
    assert_equal 'val"ue', ann2.value
    
    # Regexp strip

    ann3 = Annotation.create(:attribute_name => "regex_strip", 
                            :value => 'v1,al"ue23x4', 
                            :source_type => source.class.name, 
                            :source_id => source.id,
                            :annotatable_type => "Book",
                            :annotatable_id => 1)
    
    assert ann3.valid?
    assert_equal 'v,al"uex', ann3.value

    # Don't strip!
    
    ann4 = Annotation.create(:attribute_name => "dont_strip", 
                            :value => 'v,al"ue', 
                            :source_type => source.class.name, 
                            :source_id => source.id,
                            :annotatable_type => "Book",
                            :annotatable_id => 1)
    
    assert ann4.valid?
    assert_equal 'v,al"ue', ann4.value
  end
  
  def test_limits_per_source
    source = users(:john)
    
    bk = Book.create
    
    ann1 = bk.annotations << Annotation.new(:attribute_name => "rating", 
                                    :value => 4, 
                                    :source_type => source.class.name, 
                                    :source_id => source.id)
    
    assert_not_nil ann1
    assert_equal 1, bk.annotations.length
    
    ann2 = bk.annotations << Annotation.new(:attribute_name => "rating", 
                                    :value => 1, 
                                    :source_type => source.class.name, 
                                    :source_id => source.id)
    
    assert_not_nil ann2
    assert_equal 1, bk.annotations(true).length
    
    # Check that two versions of the annotation now exist
    assert_equal 2, bk.annotations[0].versions.length
  end
  
  def test_attribute_names_to_allow_duplicates
    source = users(:john)
    
    # First test the default case of not allowing duplicates...
    
    bk1 = Book.create
    
    ann1 = bk1.annotations << Annotation.new(:attribute_name => "no_duplicates_allowed", 
                                    :value => "Hello there", 
                                    :source_type => source.class.name, 
                                    :source_id => source.id)
    
    assert_not_nil ann1
    assert_equal 1, bk1.annotations.length
    
    ann2 = bk1.annotations << Annotation.new(:attribute_name => "no_duplicates_allowed", 
                                    :value => "Hello there again", 
                                    :source_type => source.class.name, 
                                    :source_id => source.id)
    
    assert_not_nil ann2
    assert_equal 2, bk1.annotations(true).length
    
    ann3 = bk1.annotations << Annotation.new(:attribute_name => "no_duplicates_allowed", 
                                    :value => "Hello there", 
                                    :source_type => source.class.name, 
                                    :source_id => source.id)
    
    assert_equal false, ann3
    assert_equal 2, bk1.annotations(true).length
    
    
    # Then test the exceptions to the default rule...
    
    bk2 = Book.create
    
    ann4 = bk2.annotations << Annotation.new(:attribute_name => "allow_duplicates_for_this", 
                                    :value => "Hi there", 
                                    :source_type => source.class.name, 
                                    :source_id => source.id)
    
    assert_not_nil ann4
    assert_equal 1, bk2.annotations.length
    
    ann5 = bk2.annotations << Annotation.new(:attribute_name => "allow_duplicates_for_this", 
                                    :value => "Hi there again", 
                                    :source_type => source.class.name, 
                                    :source_id => source.id)
    
    assert_not_nil ann5
    assert_equal 2, bk2.annotations(true).length
    
    ann6 = bk2.annotations << Annotation.new(:attribute_name => "allow_duplicates_for_this", 
                                    :value => "Hi there", 
                                    :source_type => source.class.name, 
                                    :source_id => source.id)
    
    assert_not_nil ann6
    assert_equal 3, bk2.annotations(true).length
  end
end