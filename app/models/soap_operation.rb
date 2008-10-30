class SoapOperation < ActiveRecord::Base
  acts_as_trashable
  
  belongs_to :soap_service
  
  has_many :soap_inputs, :dependent => :destroy
  has_many :soap_outputs, :dependent => :destroy
  
  if ENABLE_SEARCH
    acts_as_solr(:fields => [ :name, :description, :endpoint ],
                 :include => [ :soap_inputs, :soap_outputs ])
  end
end
