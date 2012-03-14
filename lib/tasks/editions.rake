require 'whole_edition_translator'

namespace :editions do
  desc "Take old publications and convert to new top level editions"
  task :extract_to_whole_editions => :environment do
    WholeEdition.delete_all

    Publication.all.each do |publication|
      puts "Processing #{publication.class} #{publication.id}"
      if publication.panopticon_id.present?
        publication.editions.each do |edition|
          puts "  Into edition #{edition.id}"
          whole_edition = WholeEditionTranslator.new(publication, edition).run
          whole_edition.save!
        end
      else
        puts "No panopticon ID for #{publication.name} : #{publication.id}"
      end
    end
  end

  desc "denormalise associated users"
  task :denormalise => :environment do
    WholeEdition.all.each do |edition|
      begin
        puts "Processing #{edition.class} #{edition.id}"
        edition.denormalise_users!
        puts "   Done!"
      rescue Exception => e
        puts "   [Err] Could not denormalise edition: #{e}"
      end
    end
  end
end