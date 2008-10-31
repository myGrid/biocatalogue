class Service < ActiveRecord::Base
  acts_as_trashable
  
  has_many :service_versions, 
           :dependent => :destroy,
           :order => "version ASC"
  
  has_many :service_deployments, 
           :dependent => :destroy
  
  belongs_to :submitter,
             :class_name => "User",
             :foreign_key => "submitter_id"
  
  before_validation_on_create :generate_unique_code
  
  attr_protected :unique_code
  
  validates_presence_of :name, :unique_code
  
  validates_uniqueness_of :unique_code
  
  validates_associated :service_versions
  
  validates_associated :service_deployments
  
  validates_existence_of :submitter   # User must exist in the db beforehand.
  
  if ENABLE_SEARCH
    acts_as_solr(:fields => [ :name, :unique_code, :submitter_name ],
                 :include => [ :service_versions, :service_deployments ])
  end
  
  def submitter_name
    if self.submitter
      return submitter.display_name
    else 
      return ''
    end
  end
  
protected
  
  def generate_unique_code
    salt = rand 1000000
    
    if self.name.blank?
      errors.add_to_base("Failed to generate the unique code for the Service. The name of the service has not been set yet.")
      return false
    else
      code = "#{self.name.gsub(/[^\w\.\-]/,'_').downcase}_#{salt}"
      
      if Service.exists?(:unique_code => code)
        generate_unique_code
      else
        self.unique_code = code
      end
    end
  end
  
end
