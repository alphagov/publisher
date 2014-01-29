namespace :orphaned_editions do
  desc "Report on or destroy editions having an artefact with the state 'archived'"

  QUALIFYING_EDITION_STATES = [
    "ready",
    "amends_needed",
    "fact_check_received",
    "fact_check",
    "draft",
    "in_review",
    "lined_up"
  ]

  def orphaned_editions(state)
    Edition.where(state: state).select { |e|
      e.artefact.state == 'archived' }
  end

  def about_edition(edition)
    "Id: #{edition.id} Type: #{edition._type} Title: #{edition.title}"
  end

  desc "Report on editions having an artefact with the state 'archived'"
  task :report => :environment do
    puts "Searching for orphaned editions..."
    orphans = []
    QUALIFYING_EDITION_STATES.each do |state|
      orphans.concat(orphaned_editions(state))
    end
    if orphans.any?
      orphans.each {|o| puts "Found orphan - " + about_edition(o) }
    else
      puts "No orphaned editions found"
    end
  end

  desc "Remove editions having an artefact with the state 'archived'"
  task :destroy => :environment do
    puts "Searching for orphaned editions..."
    orphans = []
    QUALIFYING_EDITION_STATES.each do |state|
      orphaned_editions(state).each do |oe|
        orphans.concat(oe)
      end
    end
    if orphans.any?
      orphans.each do |o|
        puts "Destroying orphan - " + about_edition(o)
        o.destroy
      end
    else
      puts "No orphaned editions found"
    end
  end
end
