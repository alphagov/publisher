require "csv"

namespace :permissions do
  desc "Add an organisation to a document's access permissions list"
  task :add_organisation_access, %i[document_content_id org_content_id log_file] => :environment do |_, args|
    document = Artefact.find_by(content_id: args[:document_content_id])

    if document.nil?
      message = "Document ID #{args[:document_content_id]} not found, no permissions added for organisation with ID: #{args[:org_content_id]}"
    elsif document.latest_edition.owning_org_content_ids.include?(args[:org_content_id])
      message = "Organisation with ID: #{args[:org_content_id]} already has permission to access the document with ID: #{document.id}"
    else
      Edition.where(panopticon_id: document.id).find_each do |edition|
        owning_org_content_ids = edition.owning_org_content_ids
        owning_org_content_ids << args[:org_content_id]
        edition.update_columns(owning_org_content_ids: owning_org_content_ids)
      end
      document.save_as_task!("PermissionsAddition")
      message = "Access permission for organisation ID: #{args[:org_content_id]}, successfully assigned to document with ID: #{document.id}"
    end
    args[:log_file] ? args[:log_file].puts(message) : puts(message)
  rescue ActiveRecord::RecordNotFound => e
    error_message = "An error occurred while processing document ID #{args[:document_content_id]}: #{e.message}"
    args[:log_file] ? args[:log_file].puts(error_message) : puts(error_message)
  end

  desc "Bulk process access permissions from CSV of URLs"
  task :bulk_process_access_flags, %i[csv_filename organisation_id] => :environment do |_, args|
    log_file = File.open("/tmp/permissions_rake_log.txt", "w")
    log_file.puts("Adding access permissions for the organisation with ID - #{args[:organisation_id]}")

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
        Rake::Task["permissions:add_organisation_access"].invoke(document.content_id, args[:organisation_id], log_file)
      rescue StandardError => e
        log_file.puts "--- Error occurred ---"
        log_file.puts e.detailed_message
        log_file.puts "------"
      end
    ensure
      log_file.close
    end
  end

  desc "Remove an organisation from a document's access permissions list"
  task :remove_organisation_access, %i[document_content_id org_content_id] => :environment do |_, args|
    document_content_id = args[:document_content_id]
    org_content_id = args[:org_content_id]

    document = Artefact.find_by(content_id: document_content_id)

    if document.nil?
      puts "Document ID #{document_content_id} not found, no permissions removed for organisation with ID: #{org_content_id}"
    else
      editions = Edition.where(panopticon_id: document.id).select { |edition| edition.owning_org_content_ids.include?(org_content_id) }
      if editions.empty?
        puts "Organisation with ID #{org_content_id} did not have access to document with ID: #{document.content_id}. No permissions changed"
      else
        editions.each do |edition|
          owning_org_content_ids = edition.owning_org_content_ids - [org_content_id]
          edition.update_columns(owning_org_content_ids: owning_org_content_ids)
        end
        document.save_as_task!("PermissionsRemoval")
        puts "Access permission successfully removed for the organisation with ID #{org_content_id} from document with ID: #{document.id}"
      end
    end
  rescue ActiveRecord::RecordNotFound => e
    puts "An error occurred while processing document with ID #{document_content_id}: #{e.message}"
  end

  desc "Remove all access permissions from a document"
  task :remove_all_access_flags, %i[document_content_id] => :environment do |_, args|
    document_content_id = args[:document_content_id]
    document = Artefact.find_by(content_id: document_content_id)

    if document.nil?
      puts "Document ID #{document_content_id} not found, no permissions changed"
    else
      Edition.where(panopticon_id: document.id).find_each do |edition|
        edition.update_columns(owning_org_content_ids: [])
      end
      document.save_as_task!("PermissionsClear")
      puts "All access permissions for all organisations successfully removed from document with ID - #{document.content_id}"
    end
  rescue ActiveRecord::RecordNotFound => e
    puts "An error occurred while processing document with ID #{document_content_id}: #{e.message}"
  end
end
