class CreateSavedSearchScopes < ActiveRecord::Migration
  def self.up
    create_table :saved_search_scopes do |t|
      t.integer :saved_search_id, :null => false
      t.string :resource
      t.text :filters
      
      t.timestamps
    end
  end

  def self.down
    drop_table :saved_search_scopes
  end
end
