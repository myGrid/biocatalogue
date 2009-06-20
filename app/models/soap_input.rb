# BioCatalogue: app/models/soap_input.rb
#
# Copyright (c) 2008, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

class SoapInput < ActiveRecord::Base
  if ENABLE_CACHE_MONEY
    is_cached :repository => $cache
    index :soap_operation_id
  end
  
  acts_as_trashable
  
  acts_as_annotatable
  
  belongs_to :soap_operation
  
  if ENABLE_SEARCH
    acts_as_solr(:fields => [ :name, :description, :computational_type ] )
  end
  
  if USE_EVENT_LOG
    acts_as_activity_logged(:models => { :referenced => { :model => :soap_operation } })
  end
end
