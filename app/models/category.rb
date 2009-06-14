# BioCatalogue: app/models/category.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

class Category < ActiveRecord::Base
  validates_presence_of :name
  
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
  
  def self.tree
    roots = [ ]
    
    self.all.each do |c|
      roots << c unless c.has_parent?
    end
    
    return roots.sort { |a,b| a.name <=> b.name }
  end
  
  def has_parent?
    not self.parent_id.nil?
  end

  def has_children?
   not Category.find_all_by_parent_id(self.id).empty?
  end  
end
