class CreateRestServiceSubstructure < ActiveRecord::Migration
  def self.up
    
    # REST Resources
    
    create_table :rest_resources do |t|
      t.belongs_to  :rest_service,  :null => false
      t.string      :path,          :null => false
      t.text        :description
      t.integer     :parent_resource_id
      
      t.timestamps
    end
    
    add_index :rest_resources, [ :rest_service_id ]
    
    # REST Methods
    
    create_table :rest_methods do |t|
      t.belongs_to  :rest_resource,  :null => false
      t.string      :method_type,    :null => false
      t.text        :description
      
      t.timestamps
    end
    
    add_index :rest_methods, [ :rest_resource_id ]
    
    # REST Parameters
    
    create_table :rest_parameters do |t|
      t.string  :name,                :null => false
      t.text    :description
      t.string  :param_style,         :null => false
      t.string  :computational_type
      t.string  :default_value
      t.boolean :required,            :default => 0
      t.boolean :multiple,            :default => 0
      t.boolean :constrained,         :default => 0
      t.text    :constrained_options
      
      t.timestamps
    end
    
    # REST Representations
    
    create_table :rest_representations do |t|
      t.string  :content_type,  :null => false
      t.text    :description
      t.string  :http_status
      
      t.timestamps
    end
    
    # REST Method Paramaters (joining table)
    
    create_table :rest_method_parameters do |t|
      t.belongs_to  :rest_method,       :null => false
      t.integer     :rest_parameter_id, :null => false
      t.string      :http_cycle,        :null => false
      
      t.timestamps
    end
    
    add_index :rest_method_parameters, [ :rest_method_id ]
    add_index :rest_method_parameters, [ :rest_method_id, :http_cycle ]
    
    # REST Method Representations (joining table)
    
    create_table :rest_method_representations do |t|
      t.belongs_to  :rest_method,             :null => false
      t.integer     :rest_representation_id,  :null => false
      t.string      :http_cycle,              :null => false
      
      t.timestamps
    end
    
    add_index :rest_method_representations, [ :rest_representation_id ]
    add_index :rest_method_representations, [ :rest_representation_id, :http_cycle ], :name => "index_rest_method_representations_repid_and_httpcycle"
    
  end

  def self.down
    drop_table :rest_resources
    drop_table :rest_methods
    drop_table :rest_parameters
    drop_table :rest_representations
    drop_table :rest_method_parameters
    drop_table :rest_method_representations
  end
end
