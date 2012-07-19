require 'csv'

class LicenceIdentifierMigrator

  MAPPING_FILENAME = 'licence_mappings.csv'
  
  def self.update_all
    counter = 0
    licence_mappings = mappings_as_hash
    LicenceEdition.all.each do |licence_edition|
      licence_identifier = licence_mappings[licence_edition.licence_identifier.to_s]
      if licence_identifier
        licence_edition.update_attribute("licence_identifier", licence_identifier)
        counter += 1
      end
      
      done(counter, "\r")
    end
    
    done(counter, "\n")
  end
  
  def self.data_file_path(filename)
    Rails.root.join('data', filename)
  end
  
  def self.read_mappings
    CSV.read(self.class.data_file_path(MAPPING_FILENAME), headers: true)
  end
  
  def self.mappings_as_hash
    licence_mappings = {} 
    read_mappings.each do |row|
      licence_mappings[row['GDS ID']] = row['Legal_Ref_No']  
    end
    licence_mappings
  end
  
  def self.done(counter, nl)
    print "Migrated #{counter} LicenceEditions out of #{LicenceEditions.count}.#{nl}"
  end
  
end
