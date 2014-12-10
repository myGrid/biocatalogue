class WmsContactInformation < ActiveRecord::Base
  belongs_to :wms_service_node
  attr_accessible :address, :address_type, :city, :contact_organization, :contact_person_primary, :contact_position_, :country, :post_code, :state_or_province
end
