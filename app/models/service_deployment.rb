class ServiceDeployment < ActiveRecord::Base
  acts_as_trashable
  
  belongs_to :service
  
  belongs_to :provider, 
             :class_name => "ServiceProvider",
             :foreign_key => "provider_id"
  
  belongs_to :service_version
  
  validates_existence_of :provider    # Service Provider must exist in the db beforehand.
  
  validates_presence_of :service_url
  
  before_save :check_service_id
  
protected

  def check_service_id
    if self.service && self.service_version
      unless self.service.id == self.service_version.service.id 
        errors.add_to_base("The service deployment doesn't belong to the same service as the associated service version.")
        return false
      end
    end
    return true
  end
  
end
