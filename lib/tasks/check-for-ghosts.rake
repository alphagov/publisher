require 'local_authority_data_importer'
require 'local_interaction_importer'
require 'local_authority_interaction_ghost_detector'

namespace :check_for_ghosts do
  def detector
    input = LocalInteractionImporter.fetch_data()
    LocalAuthorityInteractionGhostDetector.new(input)
  end

  desc "Compare local authority interactions in our DB against the local.directgov CSV export to detect \"ghosts\"."
  task :run => :environment do
    output_filename = Rails.root.join("ghosts_in_local_authority_interactions_#{Time.zone.today.iso8601}.csv")
    CSV.open(output_filename, 'w') do |output|
      output.puts ['LA Name', 'LA SNAC', 'LGSL', 'LGIL', 'URL', 'status']

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
          output.puts [la.name, la.snac, lai.lgsl_code, lai.lgil_code, lai.url, ghost_status]
          ghosts_count += 1
          current_ghost_count += 1
        end
      end
      puts " - #{current_ghost_count} ghosts"
      puts "Total Interactions: #{total_count}, Total Ghosts: #{ghosts_count}, Data: #{output_filename}"
    end
  end

  desc "Destroy any local authority interactions that appear in our DB but not in the local.directgov CSV export."
  task :destroy, [] => :environment do |_task, args|
    possible_statuses = [:interaction_in_input_to_be_deleted, :interaction_not_in_input, :authority_not_in_input]
    statuses_to_remove =
      if args.extras.any?
        args.extras.map { |x| x.to_sym }.select { |x| possible_statuses.include? x }
      else
        [:interaction_not_in_input]
      end
    if statuses_to_remove.empty?
      puts "Usage: `rake check_for_ghosts:destroy` or `rake check_for_ghosts:destroy[statues_to_remove]`"
      puts "  If statuses_to_remove is omitted only interaction_not_in_input ghosts will be removed."
      puts "  If statuses_to_remove is provideded statuses not in #{possible_statuses.inspect} will be ignored."
    else
      puts "Removing ghost interactions with statuses: #{statuses_to_remove.inspect}"
      output_filename = Rails.root.join("removed_ghosts_in_local_authority_interactions_#{Time.zone.today.iso8601}.csv")
      CSV.open(output_filename, 'w') do |output|
        output.puts ['LA Name', 'LA SNAC', 'LGSL', 'LGIL', 'URL', 'status']
        total_count = destroyed_count = ghosts_count = 0
        detector.detect_ghosts do |la, lai, ghost_status|
          total_count += 1
          if ghost_status != :interaction_in_input
            ghosts_count +=1
            if statuses_to_remove.include? ghost_status
              lai.destroy
              output.puts [la.name,la.snac,lai.lgsl_code,lai.lgil_code,lai.url, ghost_status]
              destroyed_count += 1
            end
          end
          print "\rT: #{total_count} / G: #{ghosts_count} / D: #{destroyed_count}"
        end
        puts "\rTotal Interactions: #{total_count}, Total Ghosts: #{ghosts_count}, Total Destroyed: #{destroyed_count}, Data: #{output_filename}"
      end
    end
  end
end
