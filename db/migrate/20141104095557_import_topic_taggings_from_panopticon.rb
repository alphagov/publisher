class ImportTopicTaggingsFromPanopticon < Mongoid::Migration
  def self.up
    Artefact.where(owning_app: 'publisher').each do |artefact|
      Edition.where(panopticon_id: artefact.id, :state.ne => "archived").each do |edition|
        sectors = artefact.specialist_sectors.map(&:tag_id)

        edition.primary_topic = sectors.shift
        edition.additional_topics = sectors

        edition.browse_pages = artefact.sections.map(&:tag_id)

        puts "Setting tags on edition ##{edition.id} for artefact ##{artefact.id} #{artefact.name}"
        puts "-- primary topic: #{edition.primary_topic}"
        puts "-- additional topics: #{edition.additional_topics.inspect}"
        puts "-- browse pages: #{edition.browse_pages.inspect}"

        save_edition(edition)
      end
    end
  end

  def self.down
    Artefact.where(owning_app: 'publisher').each do |artefact|
      Edition.where(panopticon_id: artefact.id, :state.ne => "archived").each do |edition|
        edition.primary_topic = nil
        edition.additional_topics = []

        edition.browse_pages = []

        puts "Clearing tags on edition ##{edition.id} for artefact ##{artefact.id} #{artefact.name}"

        save_edition(edition)
      end
    end
  end

  def self.save_edition(edition)
    Edition.skip_callback(:save, :before, :check_for_archived_artefact) # Allow saving editions to archived artefacts
    edition.save(validate: false) # Skip protection of editing published editions
    Edition.set_callback(:save, :before, :check_for_archived_artefact)
  end
end
