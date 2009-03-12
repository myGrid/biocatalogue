# BioCatalogue: app/models/rest_method_parameter.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

class RestMethodParameter < ActiveRecord::Base
  acts_as_trashable
  
  validates_presence_of :rest_method_id,
                        :rest_parameter_id,
                        :http_cycle
  
  belongs_to :rest_method
  
  belongs_to :rest_parameter
end
