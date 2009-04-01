class CreateAgents < ActiveRecord::Migration
  def self.up
    create_table :agents do |t|
      t.string :name
      t.string :display_name
      
      t.timestamps
    end
    
    Agent.create(:name => "feta_importer", :display_name => "Feta Importer Agent")
  end

  def self.down
    drop_table :agents
  end
end
