class AddCompositeIndexToActions < ActiveRecord::Migration[8.1]
  # This is required to perform the migration concurrently, which prevents write locks
  # on the table whilst the index is being built
  disable_ddl_transaction!

  def change
    add_index :actions, %i[edition_id request_type created_at],
              name: "index_actions_on_edition_id_request_type_created_at",
              algorithm: :concurrently
  end
end
