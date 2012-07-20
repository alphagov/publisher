require 'csv'

class LicenceIdentifierMigrator

  # MAPPING_CSV_URL = "https://raw.github.com/alphagov/licence-finder/master/data/licence_mappings.csv"
  MAPPING_CSV_URL = "https://raw.github.com/alphagov/licence-finder/correlation_id_migration/data/licence_mappings.csv"
  
  def self.update_all
    counter = 0
    licence_mappings = mappings_as_hash
    
    LicenceEdition.marples_transport ||= Marples::NullTransport.instance
    LicenceEdition.marples_client_name ||= "LicenceIdentifierMigrator"
    
    LicenceEdition.all.each do |licence_edition|
      licence_identifier = licence_mappings[licence_edition.licence_identifier.to_s]
      if licence_identifier
        if licence_edition.state == 'published'
          clone = licence_edition.build_clone
          clone.licence_identifier = licence_identifier
          clone.save!
        else
          licence_edition.licence_identifier = licence_identifier
          licence_edition.save! 
        end
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
      licence_mappings[row['GDS ID']] = row['Legal_Ref_No']  
    end
    licence_mappings
  end
  
  def self.done(counter, nl)
    print "Migrated #{counter} LicenceEditions.#{nl}"
  end
  
end
