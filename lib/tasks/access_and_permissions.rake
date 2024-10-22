namespace :permissions do
    desc "Add an organisation to an edition's access permissions list"
    task :add_organisation_access, %i[edition_content_id org_content_id] => :environment do |_, args|
        edition = Edition.where(id: args[edition_content_id])
        if edition.owning_org_content_ids.include? args[org_content_id]
            puts "Organisation already has permission to access this document"
        else
            edition.owning_org_content_ids << args[org_content_id]
            UpdateWorker.perform_async(edition.id.to_s)
            puts "Access permission successfully assigned"
        end
    end

    desc "Remove an organisation from an edition's access permissions list"
    task :remove_organisation_access, %i[edition_content_id org_content_id] => :environment do |_, args|
        edition = Edition.where(id: args[edition_content_id])
        edition.owning_org_content_ids.delete(args[org_content_id])
        UpdateWorker.perform_async(edition.id.to_s)
        puts "Access removed from organisation"
    end

    desc "Remove all access permissions from an edition"
    task :remove_all_access_flags, %i[edition_content_id] => :environment do |_, args|
        edition = Edition.where(id: args[edition_content_id])
        edition.owning_org_content_ids.clear
        UpdateWorker.perform_async(edition.id.to_s)
        puts "All access permissions removed"
    end
end