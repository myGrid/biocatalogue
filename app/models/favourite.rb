# BioCatalogue: app/models/favourite.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

#=====
# This extends the Favourite model defined in the Favourites plugin.
#=====

require_dependency RAILS_ROOT + '/vendor/plugins/favourites/lib/app/models/favourite'

class Favourite < ActiveRecord::Base
  
  if USE_EVENT_LOG
    acts_as_activity_logged :models => { :culprit => { :model => :user },
                                         :referenced => { :model => :favouritable } }
  end
  
end