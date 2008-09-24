class ServiceProvider < ActiveRecord::Base
  validates_presence_of :name
  has_many :annotations, :as => :annotatable
  has_many :web_services
end
