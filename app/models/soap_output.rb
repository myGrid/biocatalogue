# BioCatalogue: app/models/soap_output.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

class SoapOutput < ActiveRecord::Base
  if ENABLE_CACHE_MONEY
    is_cached :repository => $cache
    index :soap_operation_id
  end
  
  acts_as_trashable
  
  acts_as_annotatable
  
  belongs_to :soap_operation
  
  serialize :computational_type_details
  
  if ENABLE_SEARCH
    acts_as_solr(:fields => [ :name, :description, :computational_type,
                              { :associated_service_id => :r_id } ])
  end
  
  if USE_EVENT_LOG
    acts_as_activity_logged(:models => { :referenced => { :model => :soap_operation } })
  end
  
  protected
  
  def associated_service_id
    BioCatalogue::Mapper.map_compound_id_to_associated_model_object_id(BioCatalogue::Mapper.compound_id_for(self.class.name, self.id), "Service")
  end
end
