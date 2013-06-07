# BioCatalogue: app/models/favourite.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

#=====
# This extends the Favourite model defined in the Favourites plugin.
#=====

require_dependency Rails.root.to_s + '/vendor/plugins/favourites/lib/app/models/favourite'

class Favourite < ActiveRecord::Base
  if ENABLE_CACHE_MONEY
    is_cached :repository => $cache
    index :user_id, :limit => 2000, :buffer => 100
    index [ :favouritable_type, :favouritable_id ], :limit => 2000, :buffer => 100
  end
  
  if ENABLE_TRASHING
    acts_as_trashable
  end
  
  if USE_EVENT_LOG
    acts_as_activity_logged :models => { :culprit => { :model => :user },
                                         :referenced => { :model => :favouritable } }
  end
  
  def to_inline_json
    self.favouritable.to_inline_json
  end
end