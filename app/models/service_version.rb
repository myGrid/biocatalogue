class ServiceVersion < ActiveRecord::Base
  acts_as_trashable
  
  belongs_to :service
  
  belongs_to :service_versionified,
             :polymorphic => true,
             :dependent => :destroy
  
  has_many :service_deployments
  
  belongs_to :submitter,
             :class_name => "User",
             :foreign_key => "submitter_id"
  
  validates_presence_of :version, :version_display_text
  
  if ENABLE_SEARCH
    acts_as_solr(:fields => [ ],
                 :include => [ :service_versionified ])
  end
  
  if USE_EVENT_LOG
    acts_as_activity_logged(:models => { :culprit => { :model => :submitter },
                                         :referenced => { :model => :service } })
  end
end
