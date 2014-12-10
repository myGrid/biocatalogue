class WmsLayerCrs < ActiveRecord::Base
  belongs_to :wms_layer
  attr_accessible :crs
end
