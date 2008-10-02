class ServiceVersion < ActiveRecord::Base
  belongs_to :service
  
  belongs_to :service_versionified,
             :polymorphic => true
  
  has_many :service_deployments
end
