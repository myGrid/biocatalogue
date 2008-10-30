class SoapOutput < ActiveRecord::Base
  acts_as_trashable
  
  belongs_to :soap_operation
  
  if ENABLE_SEARCH
    acts_as_solr(:fields => [ :name, :description, :computational_type ])
  end
end
