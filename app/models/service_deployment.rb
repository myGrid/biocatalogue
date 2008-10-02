class ServiceDeployment < ActiveRecord::Base
  belongs_to :service
  
  belongs_to :provider, 
             :class_name => "ServiceProvider"
  
  belongs_to :service_version
end
