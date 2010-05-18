class CreateSoapServiceChanges < ActiveRecord::Migration
  def self.up
    create_table :soap_service_changes do |t|
      t.column :soap_service_id, :integer
      t.column :changelog, :text, :limit => 1.megabytes, :nil => false
      
      t.timestamps
    end
  end

  def self.down
    drop_table :soap_service_changes
  end
end
