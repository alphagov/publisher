require 'local_authority_interaction_ghost_detector'

namespace :check_for_ghosts do
  desc "Compare local authority interactions in our DB against the local.directgov CSV export to detect \"ghosts\"."
  task :run => :environment do
    File.open(Rails.root.join('local_authority_service_details.csv'), 'r:windows-1252:UTF-8') do |input|
      detector = LocalAuthorityInteractionGhostDetector.new(input)

      output_filename = Rails.root.join("ghosts_in_local_authority_interactions_#{Time.zone.today.iso8601}.csv")
      CSV.open(output_filename, 'w') do |output|
        output.puts ['LA Name', 'LA SNAC', 'LGSL', 'LGIL', 'URL']

        current_la = nil
        total_count = ghosts_count = current_ghost_count = 0

        detector.detect_ghosts do |la, lai, ghost_status|
          if current_la != la
            if current_la.present?
              puts " - #{current_ghost_count} ghosts"
            end
            print "#{la.name} (#{la.snac}): #{la.local_interactions.count} interactions"
            current_la = la
            current_ghost_count = 0
          end
          total_count += 1
          if ghost_status != :interaction_in_input
            output.puts [la.name, la.snac, lai.lgsl_code, lai.lgil_code, lai.url]
            ghosts_count += 1
            current_ghost_count += 1
          end
        end
        puts " - #{current_ghost_count} ghosts"
        puts "Total Interactions: #{total_count}, Total Ghosts: #{ghosts_count}"
      end
    end
  end
end
