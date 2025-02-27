class CreateArtefactAction < ActiveRecord::Migration[7.1]
  def change
    create_table :artefact_actions do |t|
      t.string :action_type
      t.jsonb :snapshot
      t.string :task_performed_by
      t.timestamps
      t.belongs_to :artefact, index: true, foreign_key: true
      # t.belongs_to :user
    end
  end
end
