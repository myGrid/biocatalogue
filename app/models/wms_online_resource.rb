class WmsOnlineResource < ActiveRecord::Base
  belongs_to :wms_service_node
  attr_accessible :xlink_href, :xlink_type, :xmlns_link
end
