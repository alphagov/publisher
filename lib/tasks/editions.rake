require 'whole_edition_translator'

namespace :editions do
  task :extract_to_whole_editions => :environment do
    Publication.all.each do |publication|
      if publication.panopticon_id.present?
        publication.editions.each do |edition|
          whole_edition = WholeEditionTranslator.new(edition).run
          whole_edition.save!
        end
      else
        puts "No panopticon ID for #{publication.name} : #{publication.id}"
      end
    end
  end
end