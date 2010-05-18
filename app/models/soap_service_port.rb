# BioCatalogue: app/models/soap_service_port.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

class SoapServicePort < ActiveRecord::Base
  acts_as_trashable
  
  acts_as_archived
  
  belongs_to :soap_service
  
  has_many :soap_operations
  
  validates_presence_of :name
  
  validates_url_format_of :location,
                          :allow_nil => false,
                          :message => 'is not valid'
end
