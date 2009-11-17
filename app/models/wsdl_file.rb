# BioCatalogue: app/models/wsdl_file.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

class WsdlFile < ActiveRecord::Base
  
  has_one :soap_service
  
  belongs_to :content_blob
  
  validates_presence_of :location,
                        :content_blob_id
  
end
