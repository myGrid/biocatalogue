class AddWmsLayerIdToWmsKeywordlist < ActiveRecord::Migration
  def change
    add_column :wms_keywordlists, :wms_layer_id, :integer
  end
end
