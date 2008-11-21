# BioCatalogue: app/models/rest_service.rb
#
# Copyright (c) 2008, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

class RestService < ActiveRecord::Base
  acts_as_trashable
end
