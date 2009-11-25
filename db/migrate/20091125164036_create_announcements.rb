class CreateAnnouncements < ActiveRecord::Migration
  def self.up
    create_table :announcements do |t|
      t.string  :item_type
      t.integer :item_id
      t.integer :user_id, :nil => false
      t.string  :title, :nil => false
      t.text    :body
      
      t.timestamps
    end
  end

  def self.down
    drop_table :announcements
  end
end
