class LicenceIdentifierMigrator

  LICENCE_MAPPING_URL = "https://raw.github.com/alphagov/licence-finder/correlation_id_migration/data/licence_gds_ids.yaml"
  
  def self.update_all
    counter = 0
    licence_mappings = mappings_as_hash
    puts licence_mappings
    
    LicenceEdition.all.each do |licence_edition|
      licence_identifier = licence_mappings[licence_edition.licence_identifier.to_i]
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
  
  def self.mappings_as_hash
    YAML.load(Curl::Easy.http_get(LICENCE_MAPPING_URL).body_str)
  end

  def self.done(counter, nl)
    print "Migrated #{counter} LicenceEditions.#{nl}"
  end
  
end
