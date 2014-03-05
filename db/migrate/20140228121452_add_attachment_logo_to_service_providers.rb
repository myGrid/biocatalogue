class AddAttachmentLogoToServiceProviders < ActiveRecord::Migration
  def self.up
    change_table :service_providers do |t|
      t.attachment :logo
    end
  end

  def self.down
    drop_attached_file :service_providers, :logo
  end
end
