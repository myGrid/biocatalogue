class ServiceVersion < ActiveRecord::Base
  acts_as_trashable
  
  belongs_to :service
  
  belongs_to :service_versionified,
             :polymorphic => true
  
  has_many :service_deployments
  
  validates_presence_of :version, :version_display_text
  
  if ENABLE_SEARCH
    acts_as_solr(:fields => [ ],
                 :include => [ :service_versionified ])
  end
end
