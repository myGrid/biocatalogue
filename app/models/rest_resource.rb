# BioCatalogue: app/models/rest_resource.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

class RestResource < ActiveRecord::Base
  if ENABLE_CACHE_MONEY
    is_cached :repository => $cache
    index :rest_service_id
    index :parent_resource_id
  end
  
  acts_as_trashable
  
  acts_as_annotatable
  
  validates_presence_of :rest_service_id, 
                        :path
                        
  belongs_to :rest_service
  
  belongs_to :parent_resource,
             :class_name => "RestResource",
             :foreign_key => "parent_resource_id"
  
  has_many :rest_methods, 
           :dependent => :destroy,
           :include => [ :rest_method_parameters, :rest_method_representations ]
           
  if ENABLE_SEARCH
    acts_as_solr(:fields => [ :path, :description ])
  end
  
  if USE_EVENT_LOG
    acts_as_activity_logged(:models => { :referenced => { :model => :rest_service } })
  end
end
