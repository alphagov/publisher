desc "Update a mainstream slug.\n
See original documentation @ https://github.com/alphagov/wiki/wiki/Changing-GOV.UK-URLs#making-the-change"

task :update_mainstream_slug, [:old_slug, :new_slug] => :environment do |_task, args|
  MainstreamSlugUpdater.new(args[:old_slug], args[:new_slug], Logger.new(STDOUT)).update
end
