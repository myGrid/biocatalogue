class FavouritesMigrationV1 < ActiveRecord::Migration
  
  def self.up
    create_table :favourites, :force => true do |t|
      t.belongs_to :favouritable, :polymorphic => true
      t.belongs_to :user
      
      t.timestamps
    end
  
    add_index :favourites, [ "user_id" ], :name => "favourites_user_id_index"
    add_index :favourites, [ "favouritable_type", "favouritable_id" ], :name => "favourites_favouritable_index"
  end

  def self.down
    drop_table :favourites
  end
  
end