class CreateSoaplabServers < ActiveRecord::Migration
  def self.up
    create_table :soaplab_servers do |t|
      t.string :name
      t.string :location

      t.timestamps
    end
  end

  def self.down
    drop_table :soaplab_servers
  end
end
