# BioCatalogue: test/unit/lib/bio_catalogue/tags_test.rb
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

require 'test_helper'

class TagsTest < ActionView::TestCase
  
  def setup
    @all_tag_entries = [ ]
    
    @all_tag_entries << Factory(:annotation, :attribute_name => "tag", :value => "e")
    @all_tag_entries << Factory(:annotation, :attribute_name => "tag", :value => "e")
    @all_tag_entries << Factory(:annotation, :attribute_name => "tag", :value => "c")
    @all_tag_entries << Factory(:annotation, :attribute_name => "tag", :value => "c")
    @all_tag_entries << Factory(:annotation, :attribute_name => "tag", :value => "d")
    @all_tag_entries << Factory(:annotation, :attribute_name => "tag", :value => "A")
    @all_tag_entries << Factory(:annotation, :attribute_name => "tag", :value => "E")
    @all_tag_entries << Factory(:annotation, :attribute_name => "tag", :value => "b")
    
    unless @all_tag_entries.compact.length == 8
      raise "Failed to set up TagsTest - the Factory create methods didn't work as expected"
    end
    
    @unique_tags_length = 5
  end
  
  test "Test get_tags" do
    
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
    
    assert_equal "d", tags.last["name"], "Incorrect last tag name"
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
    
    assert_equal @unique_tags_length, tags_page_1.total_entries, "Incorrect number of total entries"
    assert_equal (@unique_tags_length.to_f / per_page.to_f).ceil, tags_page_1.total_pages, "Incorrect number of pages"
    
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
    assert_equal "d", tags_page_2.first["name"], "Incorrect first tag name"
    assert_equal 1, tags_page_2.first["count"], "Incorrect first tag count"
    assert_equal "A", tags_page_2.last["name"], "Incorrect last tag name"
    assert_equal 1, tags_page_2.last["count"], "Incorrect last tag count"
    
    # Third page
    assert_equal "b", tags_page_3.first["name"], "Incorrect first tag name"
    assert_equal 1, tags_page_3.first["count"], "Incorrect first tag count"
    # ---
    
    # ---
    # With :page and :per_page and :sort => :name
    tags_page_1 = BioCatalogue::Tags.get_tags(:sort => :name, :per_page => per_page, :page => 1)
    tags_page_2 = BioCatalogue::Tags.get_tags(:sort => :name, :per_page => per_page, :page => 2)
    tags_page_3 = BioCatalogue::Tags.get_tags(:sort => :name, :per_page => per_page, :page => 3)
    tags_page_4 = BioCatalogue::Tags.get_tags(:sort => :name, :per_page => per_page, :page => 4)
    
    assert_equal @unique_tags_length, tags_page_1.total_entries, "Incorrect number of total entries"
    assert_equal (@unique_tags_length.to_f / per_page.to_f).ceil, tags_page_1.total_pages, "Incorrect number of pages"
    
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
    # With :page and :per_page and :limit
    tags_page_1 = BioCatalogue::Tags.get_tags(:per_page => per_page, :page => 1, :limit => limit)
    tags_page_2 = BioCatalogue::Tags.get_tags(:per_page => per_page, :page => 2, :limit => limit)
    
    assert_equal limit, tags_page_1.total_entries, "Incorrect number of total entries"
    assert_equal (limit.to_f / per_page.to_f).ceil, tags_page_1.total_pages, "Incorrect number of pages"
    
    assert_equal per_page, tags_page_1.length, "Incorrect number of tags on page"
    assert_equal 1, tags_page_2.length, "Incorrect number of tags on page"
    
    # First page
    assert_equal "e", tags_page_1.first["name"], "Incorrect first tag name"
    assert_equal 3, tags_page_1.first["count"], "Incorrect first tag count"
    assert_equal "c", tags_page_1.last["name"], "Incorrect last tag name"
    assert_equal 2, tags_page_1.last["count"], "Incorrect last tag count"
    
    # Second page
    assert_equal "d", tags_page_2.first["name"], "Incorrect first tag name"
    assert_equal 1, tags_page_2.first["count"], "Incorrect first tag count"
    # ---
  end
  
end
