namespace :orphaned_editions do
  QUALIFYING_EDITION_STATES = %w[
    ready
    amends_needed
    fact_check_received
    fact_check
    draft
    in_review
  ].freeze

  desc "Report on editions having an artefact with the state 'archived'"
  task report: :environment do
    puts "Searching for orphaned editions..."

    orphans = QUALIFYING_EDITION_STATES.flat_map do |state|
      Edition.where(state: state).select { |e| e.artefact.state == "archived" }
    end

    if orphans.any?
      orphans.each do |o|
        puts "Found orphan - Id: #{o.id} Type: #{o._type} o: #{edition.title}"
      end
    else
      puts "No orphaned editions found"
    end
  end

  desc "Remove editions having an artefact with the state 'archived'"
  task destroy: :environment do
    puts "Searching for orphaned editions..."

    orphans = QUALIFYING_EDITION_STATES.flat_map do |state|
      Edition.where(state: state).select { |e| e.artefact.state == "archived" }
    end

    if orphans.any?
      orphans.each do |o|
        puts "Destroying orphan - Id: #{o.id} Type: #{o._type} o: #{edition.title}"
        o.destroy!
      end
    else
      puts "No orphaned editions found"
    end
  end
end
