require "csv"

namespace :permissions do
  desc "Add an organisation to a document's access permissions list"
  task :add_organisation_access, %i[document_content_id org_content_id log_file] => :environment do |_, args|
    document = Artefact.find_by(id: args[:document_content_id])

    if document.nil?
      message = "Document ID #{args[:document_content_id]} not found, no permissions changed."
    elsif document.latest_edition.owning_org_content_ids.include?(args[:org_content_id])
      message = "Organisation already has permission to access the document with ID - #{document.id}"
    else
      Edition.where(panopticon_id: document.id).each do |edition|
        edition.owning_org_content_ids << args[:org_content_id]
        edition.save!(validate: false)
      end
      document.save_as_task!("PermissionsAddition")
      message = "Access permission successfully assigned to document with ID - #{document.id}"
    end
    args[:log_file] ? args[:log_file].puts(message) : puts(message)
  rescue StandardError => e
    error_message = "An error occurred while processing document ID #{args[:document_content_id]}: #{e.message}"
    args[:log_file] ? args[:log_file].puts(error_message) : puts(error_message)
  end

  desc "Bulk process access permissions from CSV of URLs - See doc"
  task :bulk_process_access_flags, %i[csv_filename organisation_id] => :environment do |_, args|
    log_file = File.new("/tmp/permissions_rake_log.txt", "w")

    begin
      CSV.foreach(args[:csv_filename], headers: true) do |row|
        path = row[1]
        path&.slice!("https://www.gov.uk/")
        document = Artefact.find_by(slug: path)

        if document.nil?
          log_file.puts "Document with slug '#{path}' not found. Skipping..."
          next
        end

        Rake::Task["permissions:add_organisation_access"].reenable
        Rake::Task["permissions:add_organisation_access"].invoke(document.id, args[:organisation_id], log_file)
      rescue Mongoid::Errors::DocumentNotFound => e
        log_file.puts "--- Document not found error ---"
        log_file.puts e.detailed_message
        log_file.puts "------"
      end
    ensure
      log_file.close
    end
  end
end
