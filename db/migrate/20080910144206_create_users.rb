class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users do |t|
      t.string :email
      t.string :crypted_password
      t.string :salt
      t.datetime :activated_at
      t.string :security_token
      t.string :display_name
      t.string :openid_url
      t.integer :role_id
      t.text :affiliation
      t.string :country

      t.timestamps
    end
  end

  def self.down
    drop_table :users
  end
end
