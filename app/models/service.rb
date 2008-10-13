class Service < ActiveRecord::Base
  acts_as_trashable
  
  has_many :service_versions, 
           :dependent => :destroy
  
  has_many :service_deployments, 
           :dependent => :destroy
  
  has_many :annotations, 
           :as => :annotatable,
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
end
