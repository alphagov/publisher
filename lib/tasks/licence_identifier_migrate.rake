require 'licence_identifier_migrator'

desc "Maps old correlation_ids stored in the LicenceEdition licence_identifier field to legal_ref_ids"
task licence_identifier_migrate: ["licence_identifier_migrate:update_all"]

namespace :licence_identifier_migrate do
  desc "sub task to update licence_identifiers"
  task update_all: :environment do
    LicenceIdentifierMigrator.update_all
  end
end
