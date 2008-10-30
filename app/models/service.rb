class Service < ActiveRecord::Base
  acts_as_trashable
  
  has_many :service_versions, 
           :dependent => :destroy
  
  has_many :service_deployments, 
           :dependent => :destroy
  
  belongs_to :submitter,
             :class_name => "User",
             :foreign_key => "submitter_id"
             
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
end
