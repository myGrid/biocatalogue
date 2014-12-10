class WmsKeywordlist < ActiveRecord::Base
  belongs_to :wms_service_node
  belongs_to :wms_layer
  attr_accessible :id, :keyword
end
