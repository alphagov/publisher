class SynchroniseArtefactKindsWithLatestEditionFormats < Mongoid::Migration
  def self.up
    # We don't want to run any update callbacks, just change the column
    Artefact.skip_callback(:update, :after, :update_editions)

    Artefact.each do |artefact|
      latest_edition = artefact.latest_edition
      next if latest_edition.nil?
      next if latest_edition.kind_for_artefact == artefact.kind

      puts "Changing #{artefact.slug} (#{artefact.content_id}) from #{artefact.kind} to #{latest_edition.kind_for_artefact}"
      artefact.update_attribute(:kind, latest_edition.kind_for_artefact)
    end

    # restore the update callback for future migrations
    Artefact.set_callback(:update, :after, :update_editions)
  end

  def self.down
  end
end
