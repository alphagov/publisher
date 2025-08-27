class CreateArtefactAction < ActiveRecord::Migration[7.1]
  def change
    create_table :artefact_actions do |t|
      t.text :mongo_id
      t.string :action_type
      t.jsonb :snapshot
      t.string :task_performed_by
      t.timestamps
      t.references :user, foreign_key: true
      t.references :artefact, index: true, foreign_key: true
    end
  end
end
