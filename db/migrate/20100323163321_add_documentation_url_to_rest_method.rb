class AddDocumentationUrlToRestMethod < ActiveRecord::Migration
  def self.up
    add_column :rest_methods, :documentation_url, :string
    execute 'UPDATE rest_methods SET documentation_url = NULL'
  end

  def self.down
    remove_column :rest_methods, :documentation_url
  end
end
