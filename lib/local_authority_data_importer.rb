require 'csv'

class LocalAuthorityDataImporter

  def self.update_all
    LocalServiceImporter.update
    LocalInteractionImporter.update
    LocalContactImporter.update
  end

  def self.update
    fh = fetch_data
    begin
      new(fh).run
    ensure
      fh.close
    end
  end

  def self.fetch_http_to_file(url)
    fh = Tempfile.new(['local_authority_data', 'csv'])
    fh.set_encoding('ascii-8bit')

    uri = URI.parse(url)
    fh.write Net::HTTP.get(uri)

    fh.rewind
    fh.set_encoding('windows-1252', 'UTF-8')
    fh
  end

  def initialize(fh)
    @filehandle = fh
  end

  def run
    CSV.new(@filehandle, headers: true).each do |row|
      process_row(row)
    end
  end
end
