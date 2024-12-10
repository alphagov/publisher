class ArtefactAction < ActiveRecord::Migration[7.1]
  def change
    create_table :artefact_actions do |t|
      t.string :action_type
      t.json :snapshot
      t.string :task_performed_by
    end
  end
end
