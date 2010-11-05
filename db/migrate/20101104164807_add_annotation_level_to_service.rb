class AddAnnotationLevelToService < ActiveRecord::Migration
  def self.up
    add_column :services, :annotation_level, :integer, :default => 0
  end

  def self.down
    remove_column :services, :annotation_level
  end
end
