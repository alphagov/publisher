class UpdateDefaultEditionStartButtonText < Mongoid::Migration
  def self.up
    TransactionEdition.where(start_button_text: nil).update_all(start_button_text: "Start now")
  end

  def self.down
    # This cannot be rolled back because we don't know which editions had a missing start_button_text field
  end
end
