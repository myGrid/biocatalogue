class Service < ActiveRecord::Base
  has_many :service_versions, 
           :dependent => :destroy
  
  has_many :service_deployments, 
           :dependent => :destroy
  
  has_many :annotations, 
           :as => :annotatable, 
           :dependent => :destroy
  
  
end
