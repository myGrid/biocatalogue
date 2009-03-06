# BioCatalogue: app/models/soap_operation.rb
#
# Copyright (c) 2008, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

class SoapOperation < ActiveRecord::Base
  acts_as_trashable
  
  acts_as_annotatable
  
  belongs_to :soap_service
  
  has_many :soap_inputs, :dependent => :destroy
  has_many :soap_outputs, :dependent => :destroy
  
  if ENABLE_SEARCH
    acts_as_solr(:fields => [ :name, :description, :parent_port_type ], :auto_commit => false )
  end
  
  if USE_EVENT_LOG
    acts_as_activity_logged(:models => { :referenced => { :model => :soap_service } })
  end
end
