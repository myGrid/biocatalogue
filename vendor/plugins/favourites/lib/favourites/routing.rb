module Favourites #:nodoc:
  def self.map_routes(map, collection={}, member={}, requirements={})
    map.resources :favourites,
                  :collection => { }.merge(collection),
                  :member => { }.merge(member),
                  :requirements => { }.merge(requirements)
  end
end
