class CreateArtefactAction < ActiveRecord::Migration[7.1]
  def change
    create_table :artefact_actions do |t|
      t.string :action_type
      t.json :snapshot
      t.string :task_performed_by
      t.string :artefact_id
      t.string :user_id
      t.datetime :created_at
    end
  end
end
