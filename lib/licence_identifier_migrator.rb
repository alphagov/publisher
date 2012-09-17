require "net/http"
require "uri"

class LicenceIdentifierMigrator

  LICENCE_MAPPING_URL = "https://raw.github.com/alphagov/licence-finder/correlation_id_migration/data/licence_gds_ids.yaml"
  
  def self.update_all
    counter = 0
    licence_mappings = mappings_as_hash
    
    LicenceEdition.all.each do |licence_edition|
      licence_identifier = licence_mappings[licence_edition.licence_identifier.to_i]
      if licence_identifier
        licence_edition.licence_identifier = licence_identifier
        if licence_edition.save(validate: false) 
          counter += 1
        end
      end
      done(counter, "\r")
    end
    done(counter, "\n")
  end
  
  def self.mappings_as_hash
    uri = URI.parse(LICENCE_MAPPING_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    request = Net::HTTP::Get.new(uri.request_uri)
    response = http.request(request)
    YAML.load(response.body)
  end

  def self.done(counter, nl)
    print "Migrated #{counter} LicenceEditions.#{nl}"
  end
  
end
