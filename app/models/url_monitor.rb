# BioCatalogue: app/models/url_monitor.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

class UrlMonitor < ActiveRecord::Base

  belongs_to :parent , 
             :polymorphic => true
  
  has_one :service_test, 
          :as => :test, 
          :dependent => :destroy

  validates_presence_of :parent_type,
                        :parent_id,
                        :property
  
  # Helper class method to look up a parent object
  # given the parent object class name and id 
  def self.find_parent(parent_str, parent_id)
    parent_str.constantize.find(parent_id)
  end
  
  # Finder to get the entry for the parent specified
  def self.entry_for(parent_type, parent_id, property)
    UrlMonitor.find(:first, 
                    :conditions => { :parent_id => parent_id, :parent_type => parent_type, :property => property.to_s },
                    :order => "created_at DESC")
  end
  
  def url
    return eval("self.parent.#{self.property}")
  end
  
  def activated?
    self.service_test.activated?
  end
  
end
