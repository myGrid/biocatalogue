class CreateDataSearchRegexes < ActiveRecord::Migration
  def self.up
    create_table :data_search_regexes do |t|
      t.string :regex_name
      t.string :regex_value, :null=>false
      t.string :regex_type, :null=>false
      t.timestamps
    end    
  end

  def self.down
    drop_table :data_search_regexes
  end
end
