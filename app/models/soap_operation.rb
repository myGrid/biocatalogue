class SoapOperation < ActiveRecord::Base
  belongs_to :soap_service
  
  has_many :soap_inputs, :dependent => :destroy
  has_many :soap_outputs, :dependent => :destroy
  has_many :annotations, :as => :annotatable
end
