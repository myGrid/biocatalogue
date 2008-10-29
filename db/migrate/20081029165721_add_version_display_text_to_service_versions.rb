class AddVersionDisplayTextToServiceVersions < ActiveRecord::Migration
  def self.up
    add_column :service_versions, :version_display_text, :string
  end

  def self.down
    remove_column :service_versions, :version_display_text
  end
end
