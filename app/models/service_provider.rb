class ServiceProvider < ActiveRecord::Base
  acts_as_trashable
  
  has_many :annotations, :as => :annotatable
  
  has_many :services
  
  validates_presence_of :name
end
