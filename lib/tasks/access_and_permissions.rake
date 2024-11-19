require "csv"

namespace :permissions do
  desc "Add an organisation to an document's access permissions list"
  task :add_organisation_access, %i[document_content_id org_content_id] => :environment do |_, args|
    document = Artefact.find_by(id: args[:document_content_id])
    if document.nil?
      puts "Document not found, no permissions changed."
    elsif document.latest_edition.owning_org_content_ids.include? args[:org_content_id]
      puts "Organisation already has permission to access this document"
    else
      Edition.where(panopticon_id: document.id).each do |edition|
        edition.owning_org_content_ids << args[:org_content_id]
        edition.save!(validate: false)
      end
      document.save_as_task!("PermissionsAddition")
      puts "Access permission successfully assigned"
    end
  end

  desc "Bulk process access permissions from CSV of URLs - See doc"
  task :bulk_process_access_flags, %i[csv_filename organisation_id] => :environment do |_, args|
    CSV.foreach(args[:csv_filename], headers: true) do |row|
      path = row[1]
      path.slice! "https://www.gov.uk/"
      document = Artefact.find_by(slug: path)

      next if document.nil?

      Rake::Task["permissions:add_organisation_access"].reenable # I prefer to do this first but can be done after if cleaner
      Rake::Task["permissions:add_organisation_access"].invoke(document.id, args[:organisation_id])
    end
  end
end
