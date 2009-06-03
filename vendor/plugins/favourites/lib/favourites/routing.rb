module Favourites #:nodoc:
  def self.map_routes(map, collection={}, member={})
    map.resources :favourites,
                  :collection => { }.merge(collection),
                  :member => { }.merge(member)
  end
end
