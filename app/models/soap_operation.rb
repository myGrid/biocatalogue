# BioCatalogue: app/models/soap_operation.rb
#
# Copyright (c) 2008, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

class SoapOperation < ActiveRecord::Base
  if ENABLE_CACHE_MONEY
    is_cached :repository => $cache
    index :soap_service_id
  end
  
  acts_as_trashable
  
  acts_as_annotatable
  
  belongs_to :soap_service
  belongs_to :soap_service_port
  
  has_many :soap_inputs, :dependent => :destroy
  has_many :soap_outputs, :dependent => :destroy
  
  if ENABLE_SEARCH
    acts_as_solr(:fields => [ :name, :description, :parent_port_type,
                              { :associated_service_id => :r_id } ] )
  end
  
  if USE_EVENT_LOG
    acts_as_activity_logged(:models => { :referenced => { :model => :soap_service } })
  end
  
  def associated_service_id
    BioCatalogue::Mapper.map_compound_id_to_associated_model_object_id(BioCatalogue::Mapper.compound_id_for(self.class.name, self.id), "Service")
  end
  
  def associated_service
    @associated_service ||= Service.find_by_id(associated_service_id)
  end
end
