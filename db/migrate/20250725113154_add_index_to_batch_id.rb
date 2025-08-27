class AddIndexToBatchId < ActiveRecord::Migration[7.1]
  def change
    add_index :link_check_reports, :batch_id, unique: true
  end
end
