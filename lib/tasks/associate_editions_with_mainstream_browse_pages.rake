namespace :migrate do
  desc "Associate Editions with mainstream browse pages using a CSV.

  The CSV should be formatted respecting the following criteria:
  - first pair of entries entries are the headers and should be 'slug' and 'tag'
  - each following pair of entries should then made of:
    - first: the slug of the Edition you want to update
    - second: the tag you want to add to that Edition

  ie:
  slug,tag
  loans-for-eu-students,loans
  contact-dvsa,driving
  "
  task :associate_editions_with_mainstream_browse_pages, [:csv_path] => [:environment] do |_, args|
    csv_file = File.new(args[:csv_path])
    slug_associations = CSVParser.new(csv_file).parse
    EditionTagger.new(slug_associations, Logger.new(STDOUT)).run
  end
end
