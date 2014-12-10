class WmsGetmapFormat < ActiveRecord::Base
  belongs_to :wms_service
  attr_accessible :format
end
