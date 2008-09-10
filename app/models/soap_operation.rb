class SoapOperation < ActiveRecord::Base
  belongs_to :soap_service
  
  has_many :soap_inputs
  has_many :soap_outputs
end
