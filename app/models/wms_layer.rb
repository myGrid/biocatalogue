class WmsLayer < ActiveRecord::Base
  belongs_to :wms_service
  attr_accessible :abstract, :east_bound_longitude, :name, :north_bound_latitude, :south_bound_latitude, :title, :west_bound_longitude
end
