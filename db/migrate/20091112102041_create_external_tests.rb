class CreateExternalTests < ActiveRecord::Migration
  def self.up
    create_table :external_tests do |t|
      t.string :name
      t.text :description
      t.string :doc_url
      t.string :provider_name
      t.string :user_id

      t.timestamps
    end
  end

  def self.down
    drop_table :external_tests
  end
end
