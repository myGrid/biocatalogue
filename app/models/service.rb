class Service < ActiveRecord::Base
  has_many :soap_services, :dependent => :destroy
  has_many :annotations, :as => :annotatable
  
  belongs_to :provider
end
