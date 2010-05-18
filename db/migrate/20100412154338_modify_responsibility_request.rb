class ModifyResponsibilityRequest < ActiveRecord::Migration
  def self.up
    add_column :responsibility_requests, :activated_at, :datetime
    add_column :responsibility_requests, :activated_by, :integer
  end

  def self.down
    remove_column :responsibility_requests, :activated_at
    remove_column :responsibility_requests, :activated_by
  end
end
