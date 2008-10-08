class ServiceProvider < ActiveRecord::Base
  has_many :annotations, :as => :annotatable
  
  has_many :services
  
  validates_presence_of :name
end
