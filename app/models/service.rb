class Service < ActiveRecord::Base
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
  
  validates_presence_of :name
  validates_presence_of :unique_code
end
