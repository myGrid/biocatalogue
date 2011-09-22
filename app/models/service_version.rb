# BioCatalogue: app/models/service_version.rb
#
# Copyright (c) 2008, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

class ServiceVersion < ActiveRecord::Base
  if ENABLE_CACHE_MONEY
    is_cached :repository => $cache
    index :service_id
    index [ :service_versionified_type, :service_versionified_id ]
    index [ :service_id, :version ]
    index [ :submitter_type, :submitter_id ]
  end
  
  acts_as_annotatable :name_field => :version
  
  belongs_to :service
  
  belongs_to :service_versionified,
             :polymorphic => true,
             :dependent => :destroy
  
  has_many :service_deployments
  
  has_submitter
  
  validates_presence_of :version, :version_display_text
  
  if ENABLE_SEARCH
    acts_as_solr(:fields => [ :version_display_text, :submitter_name,
                              { :associated_service_id => :r_id } ] )
  end
  
  if USE_EVENT_LOG
    acts_as_activity_logged(:models => { :culprit => { :model => :submitter },
                                         :referenced => { :model => :service } })
  end
  
  def associated_service_id
    @associated_service_id ||= BioCatalogue::Mapper.map_compound_id_to_associated_model_object_id(BioCatalogue::Mapper.compound_id_for(self.class.name, self.id), "Service")
  end
  
  def associated_service
    @associated_service ||= Service.find_by_id(associated_service_id)
  end

end
