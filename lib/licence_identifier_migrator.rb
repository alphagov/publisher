require 'csv'

class LicenceIdentifierMigrator

  # MAPPING_CSV_URL = "https://raw.github.com/alphagov/licence-finder/master/data/correlation_id_to_gds_id_mappings.csv"
  MAPPING_CSV_URL = "https://raw.github.com/alphagov/licence-finder/correlation_id_migration/data/correlation_id_to_gds_id_mappings.csv"
  
  def self.update_all
    counter = 0
    licence_mappings = mappings_as_hash
    
    LicenceEdition.all.each do |licence_edition|
      licence_identifier = licence_mappings[licence_edition.licence_identifier.to_s]
      if licence_identifier
        licence_edition = licence_edition.build_clone if licence_edition.state == 'published'
        licence_edition.licence_identifier = licence_identifier
        licence_edition.save! 
        counter += 1
      end
      done(counter, "\r")
    end
    done(counter, "\n")
  end
  
  def self.read_mappings
    raw_csv = Curl::Easy.http_get(MAPPING_CSV_URL).body_str
    CSV.parse(raw_csv, headers: true)
  end
  
  def self.mappings_as_hash
    licence_mappings = {} 
    read_mappings.each do |row|
      licence_mappings[row['correlation_id']] = row['gds_id']  
    end
    licence_mappings
  end
  
  def self.done(counter, nl)
    print "Migrated #{counter} LicenceEditions.#{nl}"
  end
  
end
