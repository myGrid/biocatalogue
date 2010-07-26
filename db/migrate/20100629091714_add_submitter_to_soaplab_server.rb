class AddSubmitterToSoaplabServer < ActiveRecord::Migration
  def self.up
    add_column :soaplab_servers, :submitter_id, :integer
    add_column :soaplab_servers, :submitter_type, :string
  end

  def self.down
    remove_column :soaplab_servers, :submitter_id
    remove_column :soaplab_servers, :submitter_type
  end
end
