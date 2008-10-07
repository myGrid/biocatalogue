class AddSubmitterToServices < ActiveRecord::Migration
  def self.up
    add_column :services, :submitter_id, :integer
  end

  def self.down
    remove_column :services, :submitter_id
  end
end
