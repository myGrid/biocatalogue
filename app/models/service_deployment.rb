class ServiceDeployment < ActiveRecord::Base
  belongs_to :service
  
  belongs_to :provider, 
             :class_name => "ServiceProvider",
             :foreign_key => "provider_id"
  
  belongs_to :service_version
end
