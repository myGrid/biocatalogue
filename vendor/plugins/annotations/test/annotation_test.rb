require File.dirname(__FILE__) + '/test_helper.rb'

class AnnotationTest < ActiveSupport::TestCase
  
  def test_annotation_class_loaded
    assert_kind_of Annotation, Annotation.new
  end
  
  def test_fixtures_loaded
    assert_equal 2, Book.count(:all)
    assert_equal 4, Chapter.count(:all)
    assert_equal 2, User.count(:all)
    assert_equal 2, Group.count(:all)
    assert_equal 20, Annotation.count(:all)
    
    assert_equal 1, books(:h).id
    assert_equal 2, chapters(:bh_c10).id
    assert_equal 2, users(:jane).id
    assert_equal 1, groups(:sci_fi_geeks).id
    #assert_equal 2, annotations(:bh_length_1).id   # Doesn't work due to the autonumbering used in the annotations fixtures.
  end
  
  def test_belongs_to_annotatable_association
    assert_equal books(:h), annotations(:bh_summary_1).annotatable
    assert_equal books(:r), annotations(:br_author_1).annotatable
    assert_equal chapters(:bh_c10), annotations(:bh_c10_title_1).annotatable
    assert_equal chapters(:br_c2), annotations(:br_c2_tag_2).annotatable
  end
  
  def test_belongs_to_source_association
    assert_equal users(:john), annotations(:bh_title_1).source
    assert_equal users(:jane), annotations(:br_c2_title_2).source
    assert_equal groups(:sci_fi_geeks), annotations(:br_summary_2).source
    assert_equal groups(:classical_fans), annotations(:br_c202_tag_1).source
  end
  
  def test_belongs_to_attribute_association
    assert_equal annotation_attributes(:aa_length), annotations(:bh_length_1).attribute
    assert_equal annotation_attributes(:aa_tag), annotations(:br_tag_1).attribute
  end
  
  def test_find_annotatables_with_attribute_name_and_value_class_method
    ats1 = Annotation.find_annotatables_with_attribute_name_and_value("complexity", "O(x^2)")
    assert_equal 1, ats1.length
    assert ats1[0].class != Annotation
    
    ats2 = Annotation.find_annotatables_with_attribute_name_and_value("TAG", "PROGRAMMING")
    assert_equal 1, ats2.length
    assert ats2[0].class != Annotation
    
    assert_equal 0, Annotation.find_annotatables_with_attribute_name_and_value("asfrertewt", "JBuoGU IT I\tIPyI tRyyI tpIY T YFy fY f yF").length
  end
  
  def test_find_annotatables_with_attribute_names_and_values_class_method
    ats1 = Annotation.find_annotatables_with_attribute_names_and_values(["tag" ], [ "programming", "complex", "Long" ])
    assert_equal 3, ats1.length
    assert ats1[0].class != Annotation
    
    ats2 = Annotation.find_annotatables_with_attribute_names_and_values(["rating", "complexity" ], [ "O(x^2)" ])
    assert_equal 1, ats2.length
    
    ats3 = Annotation.find_annotatables_with_attribute_names_and_values(["title", "LENGTH" ], [ "345", "Ruby Hashes", "does_not_exist_but_still_counts" ])
    assert_equal 2, ats3.length
    
    assert_equal 0, Annotation.find_annotatables_with_attribute_names_and_values([ "asfrertewt" ], [ "JBuoGU IT I\tIPyI tRyyI tpIY T YFy fY f yF" ]).length
    
    assert_equal 0, Annotation.find_annotatables_with_attribute_names_and_values([ "asfrertewt", "askiki" ], [ "JBuoGU IT I\tIPyI tRyyI tpIY T YFy fY f yF", "yfyfyyfyfyff" ]).length
  end
  
  def test_by_source_named_scope_finder
    assert_equal 7, Annotation.by_source('User', users(:john).id).length
    assert_equal 6, Annotation.by_source('User', users(:jane).id).length
    assert_equal 3, Annotation.by_source('Group', groups(:sci_fi_geeks).id).length
    assert_equal 4, Annotation.by_source('Group', groups(:classical_fans).id).length
  end
  
  def test_for_annotatable_named_scope_finder
    assert_equal 6, Annotation.for_annotatable('Book', books(:h).id).length
    assert_equal 5, Annotation.for_annotatable('Book', books(:r).id).length
    assert_equal 3, Annotation.for_annotatable('Chapter', chapters(:br_c202).id).length
    assert_equal 0, Annotation.for_annotatable('Chapter', chapters(:bh_c1).id).length 
  end
  
  def test_with_attribute_name_named_scope_finder
    assert_equal 6, Annotation.with_attribute_name('tag').length
    assert_equal 5, Annotation.with_attribute_name('title').length
    assert_equal 1, Annotation.with_attribute_name('note').length
    assert_equal 0, Annotation.with_attribute_name('does_not_exist_zzzzzz').length
  end
  
  def test_find_annotatable_class_method
    assert_equal books(:h), Annotation.find_annotatable('Book', books(:h).id)
    assert_equal books(:r), Annotation.find_annotatable('Book', books(:r).id)
    assert_equal chapters(:bh_c10), Annotation.find_annotatable('Chapter', chapters(:bh_c10).id)
    assert_equal chapters(:br_c2), Annotation.find_annotatable('Chapter', chapters(:br_c2).id)
  end
  
  def test_attribute_name_getter
    assert_equal "tag", annotations(:bh_tag_2).attribute_name.downcase
    assert_equal "title", annotations(:bh_c10_title_1).attribute_name.downcase
  end
  
  def test_annotation_create
    source = users(:john)
    
    ann = Annotation.new(:attribute_name => "tag", 
                         :value => "hot", 
                         :source_type => source.class.name, 
                         :source_id => source.id,
                         :annotatable_type => "Book",
                         :annotatable_id => 1)
    
    assert ann.valid?
    
    assert ann.save
    
    assert_equal "User", ann.source_type
  end
  
  def test_cannot_create_annotation_with_invalid_annotatable
    source = users(:john)
    
    ann1 = Annotation.new(:attribute_name => "tag", 
                          :value => "hot", 
                          :source_type => source.class.name, 
                          :source_id => source.id,
                          :annotatable_type => "Book",
                          :annotatable_id => 100)
    
    assert ann1.invalid?
    assert !ann1.save
    
    ann2 = Annotation.new(:attribute_name => "tag", 
                          :value => "hot", 
                          :source_type => source.class.name, 
                          :source_id => source.id,
                          :annotatable_type => "Whale",
                          :annotatable_id => 1)
    
    assert ann2.invalid?
    assert !ann2.save
  end
  
  def test_cannot_create_annotation_with_invalid_source
    bk = books(:h)
    
    ann1 = Annotation.new(:attribute_name => "tag", 
                          :value => "hot", 
                          :source_type => "User", 
                          :source_id => 100,
                          :annotatable_type => bk.class.name,
                          :annotatable_id => bk.id)
    
    assert ann1.invalid?
    assert !ann1.save
    
    ann2 = Annotation.new(:attribute_name => "tag", 
                          :value => "hot", 
                          :source_type => "Monkey", 
                          :source_id => 1,
                          :annotatable_type => bk.class.name,
                          :annotatable_id => bk.id)
    
    assert ann2.invalid?
    assert !ann2.save
  end
  
end