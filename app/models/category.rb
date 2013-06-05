# BioCatalogue: app/models/category.rb
#
# Copyright (c) 2009-2011, University of Manchester, The European Bioinformatics
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

class Category < ActiveRecord::Base
  if ENABLE_CACHE_MONEY
    is_cached :repository => $cache
    index :parent_id
  end

  validates_presence_of :name
  
  acts_as_annotation_value :content_field => :name
  
  belongs_to :parent,
             :class_name => "Category",
             :foreign_key => "parent_id"
  
  has_many :children,
           :class_name => "Category",
           :foreign_key => "parent_id",
           :order => "categories.name ASC"

  if USE_EVENT_LOG
    acts_as_activity_logged
  end
  
  # All categories are loaded up once and stored in memory,
  # for perf reasons.
  
  class << self
    alias_method :old_find, :find
  end
  
  def self.find(*args)
    load_categories if not defined?(@@list) or @@list.nil?
    old_find(*args)
  end
  
  def self.list
    load_categories if not defined?(@@list) or @@list.nil?
    return @@list[1...@@list.length]    
  end
  
  def self.find_by_id(id_to_find)
    puts "\n\n\n ALL OKAY HERE \n\n\n"
    load_categories if not defined?(@@list) or @@list.nil?
    return @@list[id_to_find.to_i]
  end
  
  def self.root_categories
    @@children[0]
  end
  
  # Parent/children methods here override the ones provided by rails
  # to use the array instead of an SQL query
  
  def parent
    @@list[parent_id] unless parent_id.nil?
  end
  
  def children
    @@children[id]
  end
  
  def has_parent?
    not self.parent_id.nil?
  end
  
  def has_children?
    not @@children[id].empty?
  end
  
  def ancestry
    ancestry_array = Array.new
    c = self
    until c.parent.nil?
      ancestry_array << c.parent
      c = c.parent
    end
    return ancestry_array
  end
  
  def show_ancestry
    hierarchy = "<b>" + self.name + "</b>"
    ancestry.each {|an| hierarchy = an.name + " &gt; " + hierarchy}
    return hierarchy    
  end
  
  def to_json
    data = category_hash(self)
    
    data["category"]["broader"] = category_hash(self.parent, true) if self.has_parent?
    
    if self.has_children?
      narrower_data = []
      
      self.children.each { |cat| narrower_data << category_hash(cat, true) }
      
      data["category"]["narrower"] = narrower_data
    end
    
    return data.to_json
  end
  
  def to_inline_json
    category_hash(self, true).to_json
  end
  
  def to_countless_inline_json
    category_hash(self, true, false).to_json
  end
  
protected
  
  # Loads all categories into memory, including parent => child relationships
  # to cut out any SQL queries and make processing more efficient
  def self.load_categories
    @@list = [ ]
    @@children = [ ]
    @@children[0] = [ ]   # initialize master category
    all.each do |cat|
      @@list[cat.id] = cat
      @@children[cat.id] ||= [ ]
      @@children[(cat.parent_id || 0)] << cat
    end
  end
 
private

  def category_hash(cat, make_inline=false, include_count=true)
    data = {
      "category" => {
        "name" => BioCatalogue::Util.display_name(cat)
      }
    }
    
    data["category"]["total_items_count"] = BioCatalogue::Categorising.number_of_services_for_category(cat) if include_count

    unless make_inline
      data["category"]["self"] = BioCatalogue::Api.uri_for_object(cat)
			return data
    else
      data["category"]["resource"] = BioCatalogue::Api.uri_for_object(cat)
			return data["category"]
    end
  end
end
