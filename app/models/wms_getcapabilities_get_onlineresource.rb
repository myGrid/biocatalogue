class WmsGetcapabilitiesGetOnlineresource < ActiveRecord::Base
  belongs_to :wms_service
  attr_accessible :xlink_href, :xlink_type, :xmlns_xlink
end
