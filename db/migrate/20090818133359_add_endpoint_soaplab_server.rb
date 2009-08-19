class AddEndpointSoaplabServer < ActiveRecord::Migration
  def self.up
    add_column :soaplab_servers, :endpoint, :string
  end

  def self.down
    remove_column :soaplab_servers, :endpoint
  end
end
