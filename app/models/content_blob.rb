# BioCatalogue: app/models/content_blob.rb
#
# Copyright (c) 2008, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

class ContentBlob < ActiveRecord::Base
  validates_presence_of :data
  
  if USE_EVENT_LOG
    acts_as_activity_logged
  end
end
