# BioCatalogue: test/unit/lib/bio_catalogue/tags_test.rb
#
# Copyright (c) 2011, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

require 'test_helper'

class TagsTest < ActionView::TestCase
  
  def setup
    tag_ann_entries = [ ]
    
    tag_ann_entries << Factory(:annotation, :attribute_name => "tag", :value => Tag.find_or_create_simple_tag("e"))
    tag_ann_entries << Factory(:annotation, :attribute_name => "tag", :value => Tag.find_or_create_simple_tag("e"))
    tag_ann_entries << Factory(:annotation, :attribute_name => "tag", :value => Tag.find_or_create_simple_tag("c"))
    tag_ann_entries << Factory(:annotation, :attribute_name => "tag", :value => Tag.find_or_create_simple_tag("c"))
    tag_ann_entries << Factory(:annotation, :attribute_name => "tag", :value => Tag.find_or_create_simple_tag("d"))
    tag_ann_entries << Factory(:annotation, :attribute_name => "tag", :value => Tag.find_or_create_simple_tag("A"))
    tag_ann_entries << Factory(:annotation, :attribute_name => "tag", :value => Tag.find_or_create_simple_tag("E"))
    tag_ann_entries << Factory(:annotation, :attribute_name => "tag", :value => Tag.find_or_create_simple_tag("b"))
    
    # Add another annotation that is the same tag on an annotatable as an existing one,
    # but by a different person, so that we can ensure it doesn't get counted.
    c_tag = Tag.find_or_create_simple_tag("c")
    c_tag_ann = Annotation.find(:first, :conditions => { :value_type => "Tag", :value_id => c_tag.id })
    tag_ann_entries << Factory(:annotation, :attribute_name => "tag", :value => c_tag, :annotatable => c_tag_ann.annotatable)
    
    unless tag_ann_entries.compact.length == 9
      raise "Failed to set up TagsTest - the Factory create methods didn't work as expected"
    end
    
    @unique_tags_length = 5
  end
  
  test "#get_total_items_count_for_tag_name" do
    
    assert_equal 3, BioCatalogue::Tags.get_total_items_count_for_tag_name("e")
    assert_equal 3, BioCatalogue::Tags.get_total_items_count_for_tag_name("E")
    assert_equal 2, BioCatalogue::Tags.get_total_items_count_for_tag_name("c")
    assert_equal 1, BioCatalogue::Tags.get_total_items_count_for_tag_name("a")
    assert_equal 0, BioCatalogue::Tags.get_total_items_count_for_tag_name("unknown_tag")
    
  end
  
  test "#get_tags" do
    
    limit = 3
    per_page = 2
    
    # ---
    # With ALL defaults
    
    tags = BioCatalogue::Tags.get_tags
    
    assert_equal @unique_tags_length, tags.length, "Insufficient tags"
    
    assert_equal "e", tags.first["name"], "Incorrect first tag name"
    assert_equal 3, tags.first["count"], "Incorrect first tag count"
    assert_equal "c", tags.second["name"], "Incorrect first tag name"
    assert_equal 2, tags.second["count"], "Incorrect first tag count"
    # ---
    
    # ---
    # With :limit
    tags = BioCatalogue::Tags.get_tags(:limit => limit)
    
    assert_equal limit, tags.length, "Insufficient tags"
    # ---
    
    # ---
    # With :sort => :counts
    tags = BioCatalogue::Tags.get_tags(:sort => :counts)
    
    assert_equal @unique_tags_length, tags.length, "Insufficient tags"
    
    assert_equal "e", tags.first["name"], "Incorrect first tag name"
    assert_equal 3, tags.first["count"], "Incorrect first tag count"
    # ---
    
    # ---
    # With :sort => :counts and :limit
    tags = BioCatalogue::Tags.get_tags(:sort => :counts, :limit => limit)
    
    assert_equal limit, tags.length, "Insufficient tags"
    
    assert_equal "e", tags.first["name"], "Incorrect first tag name"
    assert_equal 3, tags.first["count"], "Incorrect first tag count"
    
    assert_equal "A", tags.last["name"], "Incorrect last tag name"
    assert_equal 1, tags.last["count"], "Incorrect last tag count"
    # ---
    
    # ---
    # With :sort => :name
    tags = BioCatalogue::Tags.get_tags(:sort => :name)
    
    assert_equal @unique_tags_length, tags.length, "Insufficient tags"
    
    assert_equal "A", tags.first["name"], "Incorrect first tag name"
    assert_equal 1, tags.first["count"], "Incorrect first tag count"
    
    assert_equal "e", tags.last["name"], "Incorrect last tag name"
    assert_equal 3, tags.last["count"], "Incorrect last tag count"
    # ---
    
    # ---
    # With :sort => :name and :limit
    tags = BioCatalogue::Tags.get_tags(:sort => :name, :limit => limit)
    
    assert_equal limit, tags.length, "Insufficient tags"
    
    assert_equal "A", tags.first["name"], "Incorrect first tag name"
    assert_equal 1, tags.first["count"], "Incorrect first tag count"
    
    assert_equal "c", tags.last["name"], "Incorrect last tag name"
    assert_equal 2, tags.last["count"], "Incorrect last tag count"
    # ---
    
    # ---
    # With :page and :per_page
    tags_page_1 = BioCatalogue::Tags.get_tags(:per_page => per_page, :page => 1)
    tags_page_2 = BioCatalogue::Tags.get_tags(:per_page => per_page, :page => 2)
    tags_page_3 = BioCatalogue::Tags.get_tags(:per_page => per_page, :page => 3)
    tags_page_4 = BioCatalogue::Tags.get_tags(:per_page => per_page, :page => 4)
    
    assert_equal per_page, tags_page_1.length, "Insufficient tags on page"
    assert_equal per_page, tags_page_2.length, "Insufficient tags on page"
    assert_equal 1, tags_page_3.length, "Insufficient tags on page"
    assert_equal 0, tags_page_4.length, "Insufficient tags on page"
    
    # First page
    assert_equal "e", tags_page_1.first["name"], "Incorrect first tag name"
    assert_equal 3, tags_page_1.first["count"], "Incorrect first tag count"
    assert_equal "c", tags_page_1.last["name"], "Incorrect last tag name"
    assert_equal 2, tags_page_1.last["count"], "Incorrect last tag count"
    
    # Second page
    assert_equal "A", tags_page_2.first["name"], "Incorrect first tag name"
    assert_equal 1, tags_page_2.first["count"], "Incorrect first tag count"
    assert_equal "b", tags_page_2.last["name"], "Incorrect last tag name"
    assert_equal 1, tags_page_2.last["count"], "Incorrect last tag count"
    
    # Third page
    assert_equal "d", tags_page_3.first["name"], "Incorrect first tag name"
    assert_equal 1, tags_page_3.first["count"], "Incorrect first tag count"
    # ---
    
    # ---
    # With :page and :per_page and :sort => :name
    tags_page_1 = BioCatalogue::Tags.get_tags(:sort => :name, :per_page => per_page, :page => 1)
    tags_page_2 = BioCatalogue::Tags.get_tags(:sort => :name, :per_page => per_page, :page => 2)
    tags_page_3 = BioCatalogue::Tags.get_tags(:sort => :name, :per_page => per_page, :page => 3)
    tags_page_4 = BioCatalogue::Tags.get_tags(:sort => :name, :per_page => per_page, :page => 4)
    
    assert_equal per_page, tags_page_1.length, "Incorrect number of tags on page"
    assert_equal per_page, tags_page_2.length, "Incorrect number of tags on page"
    assert_equal 1, tags_page_3.length, "Incorrect number of tags on page"
    assert_equal 0, tags_page_4.length, "Incorrect number of tags on page"
    
    # First page
    assert_equal "A", tags_page_1.first["name"], "Incorrect first tag name"
    assert_equal 1, tags_page_1.first["count"], "Incorrect first tag count"
    assert_equal "b", tags_page_1.last["name"], "Incorrect last tag name"
    assert_equal 1, tags_page_1.last["count"], "Incorrect last tag count"
    
    # Second page
    assert_equal "c", tags_page_2.first["name"], "Incorrect first tag name"
    assert_equal 2, tags_page_2.first["count"], "Incorrect first tag count"
    assert_equal "d", tags_page_2.last["name"], "Incorrect last tag name"
    assert_equal 1, tags_page_2.last["count"], "Incorrect last tag count"
    
    # Third page
    assert_equal "e", tags_page_3.first["name"], "Incorrect first tag name"
    assert_equal 3, tags_page_3.first["count"], "Incorrect first tag count"
    # ---
    
    # ---
    # With :page and :per_page and :limit (paging should take preference!)
    tags_page_1 = BioCatalogue::Tags.get_tags(:per_page => per_page, :page => 1, :limit => limit)
    tags_page_2 = BioCatalogue::Tags.get_tags(:per_page => per_page, :page => 2, :limit => limit)
    
    tags_page_1 = BioCatalogue::Tags.get_tags(:per_page => per_page, :page => 1, :limit => limit)
    tags_page_2 = BioCatalogue::Tags.get_tags(:per_page => per_page, :page => 2, :limit => limit)
    tags_page_3 = BioCatalogue::Tags.get_tags(:per_page => per_page, :page => 3, :limit => limit)
    tags_page_4 = BioCatalogue::Tags.get_tags(:per_page => per_page, :page => 4, :limit => limit)
    
    assert_equal per_page, tags_page_1.length, "Incorrect number of tags on page"
    assert_equal per_page, tags_page_2.length, "Incorrect number of tags on page"
    assert_equal 1, tags_page_3.length, "Incorrect number of tags on page"
    assert_equal 0, tags_page_4.length, "Incorrect number of tags on page"
    
    # First page
    assert_equal "e", tags_page_1.first["name"], "Incorrect first tag name"
    assert_equal 3, tags_page_1.first["count"], "Incorrect first tag count"
    assert_equal "c", tags_page_1.last["name"], "Incorrect last tag name"
    assert_equal 2, tags_page_1.last["count"], "Incorrect last tag count"
    
    # Second page
    assert_equal "A", tags_page_2.first["name"], "Incorrect first tag name"
    assert_equal 1, tags_page_2.first["count"], "Incorrect first tag count"
    assert_equal "b", tags_page_2.last["name"], "Incorrect last tag name"
    assert_equal 1, tags_page_2.last["count"], "Incorrect last tag count"
    
    # Third page
    assert_equal "d", tags_page_3.first["name"], "Incorrect first tag name"
    assert_equal 1, tags_page_3.first["count"], "Incorrect first tag count"
    # ---
    
  end
  
  test "#get_total_tags_count" do
    assert_equal @unique_tags_length, BioCatalogue::Tags.get_total_tags_count
  end
  
  test "#get_tag_suggestions" do
    assert_equal 1, BioCatalogue::Tags.get_tag_suggestions("a").length
    assert_equal 0, BioCatalogue::Tags.get_tag_suggestions("nada").length
  end
  
end
