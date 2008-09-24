class SoapOutput < ActiveRecord::Base
  belongs_to :soap_operation
  has_many :annotations, :as => :annotatable
end
