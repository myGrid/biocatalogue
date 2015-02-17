class WmsServiceNode < ActiveRecord::Base
  belongs_to :wms_service
  attr_accessible :id, :name, :title, :version
end
