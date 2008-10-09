class SoapOutput < ActiveRecord::Base
  acts_as_trashable
  
  belongs_to :soap_operation
  has_many :annotations, :as => :annotatable
end
