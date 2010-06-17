# BioCatalogue: app/models/rest_method_representation.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

class RestMethodRepresentation < ActiveRecord::Base
  if ENABLE_CACHE_MONEY
    is_cached :repository => $cache
    index :rest_method_id
    index :rest_representation_id
    index [ :rest_method_id, :http_cycle ]
    index [ :submitter_type, :submitter_id ]
  end
  
  if ENABLE_TRASHING
    acts_as_trashable
  end

  validates_presence_of :rest_method_id,
                        :rest_representation_id,
                        :http_cycle

  has_submitter

  validates_existence_of :submitter # User must exist in the db beforehand.

  if ENABLE_SEARCH
    acts_as_solr(:fields => [ :submitter_name ] )
  end

  if USE_EVENT_LOG
    acts_as_activity_logged(:models => { :culprit => { :model => :submitter } })
  end

  belongs_to :rest_method
  
  belongs_to :rest_representation
end
