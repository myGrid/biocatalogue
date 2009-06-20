# BioCatalogue: app/models/relationship.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton
# See license.txt for details


class Relationship < ActiveRecord::Base
  if ENABLE_CACHE_MONEY
    is_cached :repository => $cache
    index :predicate
    index [ :subject_type, :subject_id ]
    index [ :object_type, :object_id ]
  end
  
  acts_as_trashable
  
  validates_presence_of :subject_id, :object_id
  
  belongs_to :subject , :polymorphic => true  #e.g service
  belongs_to :object, :polymorphic => true    #e.g soaplab_server
end
