class AddDetailsToWmsServiceNodes < ActiveRecord::Migration
  def change
    add_column :wms_service_nodes, :abstract, :string
    add_column :wms_service_nodes, :fees, :string
    add_column :wms_service_nodes, :access_constraints, :string
    add_column :wms_service_nodes, :max_width, :integer
    add_column :wms_service_nodes, :max_height, :integer
  end
end
