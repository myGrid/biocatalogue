# BioCatalogue: app/models/rest_representation.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

class RestRepresentation < ActiveRecord::Base
  acts_as_trashable
  
  validates_presence_of :content_type
end
