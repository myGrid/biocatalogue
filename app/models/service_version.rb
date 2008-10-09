class ServiceVersion < ActiveRecord::Base
  acts_as_trashable
  
  belongs_to :service
  
  belongs_to :service_versionified,
             :polymorphic => true
  
  has_many :service_deployments
  
  validates_presence_of :version
end
