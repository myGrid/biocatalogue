class WmsLayerBoundingbox < ActiveRecord::Base
  belongs_to :wms_layer
  attr_accessible :crs, :maxx, :maxy, :minx, :miny
end
