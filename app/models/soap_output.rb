class SoapOutput < ActiveRecord::Base
  acts_as_trashable
  
  belongs_to :soap_operation
  
  if ENABLE_SEARCH
    acts_as_solr(:fields => [ :name, :description, :computational_type ])
  end
  
  if USE_EVENT_LOG
    acts_as_activity_logged(:models => { :referenced => { :model => :soap_operation } })
  end
end
