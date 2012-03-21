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
        edition.denormalise_users and edition.save!
        puts "   Done!"
      rescue Exception => e
        puts "   [Err] Could not denormalise edition: #{e}"
      end
    end
  end

  desc "cache latest version number against editions"
  task :cache_version_numbers => :environment do
     WholeEdition.all.each do |edition|
      begin
        puts "Processing #{edition.class} #{edition.id}"
        if edition.subsequent_siblings.any?
          latest_edition = edition.subsequent_siblings.sort_by(&:version_number).last
          if latest_edition.in_progress?
            edition.update_sibling_in_progress(latest_edition.version_number)
          end
        end
        edition.save!
        puts "   Done!"
      rescue Exception => e
        puts "   [Err] Could not denormalise edition: #{e}"
      end
    end
  end
end