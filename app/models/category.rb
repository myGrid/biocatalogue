# BioCatalogue: app/models/category.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

class Category < ActiveRecord::Base
  validates_presence_of :name
  
  if USE_EVENT_LOG
    acts_as_activity_logged
  end
end
