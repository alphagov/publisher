desc "Update a mainstream slug

Changes are necessary in several apps when changing slugs,
so this is usually run by a fabric task.  See
https://github.com/alphagov/wiki/wiki/Changing-GOV.UK-URLs#making-the-change
for details.

This task performs the following:
- Changes the slug on all matching editions
- Changes the slug of the artefact
- Re-registers the published edition with panopticon,
  which re-registers with search
"
task :update_mainstream_slug, [:old_slug, :new_slug] => :environment do |_task, args|
  MainstreamSlugUpdater.new(args[:old_slug], args[:new_slug], Logger.new(STDOUT)).update
end
