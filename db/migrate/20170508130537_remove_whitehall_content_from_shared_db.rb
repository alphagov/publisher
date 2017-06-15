class RemoveWhitehallContentFromSharedDb < Mongoid::Migration
  def self.up
    # skip the callback which would discard publishing api drafts, this
    # migration is only about removing redundant data from the shared database
    Artefact.skip_callback(:destroy, :before, :discard_publishing_api_draft)

    Artefact.where(owning_app: "whitehall").destroy_all

    # restore the callback
    Artefact.set_callback(:destroy, :before, :discard_publishing_api_draft)
  end

  def self.down
  end
end
