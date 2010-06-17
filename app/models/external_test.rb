# BioCatalogue: app/models/external_test.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

class ExternalTest < ActiveRecord::Base
  
  if ENABLE_TRASHING
    acts_as_trashable
  end
  
  has_many :service_tests, 
           :as => :test, 
           :dependent => :destroy
  
  belongs_to :user
  
  validates_presence_of :name,
                        :description,
                        :doc_url,
                        :provider_name,
                        :user_id
  
  if USE_EVENT_LOG
    acts_as_activity_logged(:models => { :culprit => { :model => :user } })
  end
  
end
