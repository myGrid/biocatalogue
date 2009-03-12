# BioCatalogue: app/models/rest_parameter.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

class RestParameter < ActiveRecord::Base
  acts_as_trashable
  
  validates_presence_of :name, 
                        :param_style
                        
  # ===============
  # The :constrained_options field is a serialised array of values.
  # (See: http://www.salsaonrails.eu/2009/01/02/hash-serialization-in-an-activerecord-model for info)
  # ---------------
  
  serialize :constrained_options, Array
  
  def after_initialize
    self.constrained_options ||= [ ]
  end
  
  # ===============
end
