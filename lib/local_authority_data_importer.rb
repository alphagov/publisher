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

  def self.fetch_http_to_file(url, fh)
    uri = URI.parse(url)
    response = Net::HTTP.get_response(uri)

    # This will read the data in a chunked fasion, and
    # will avoid buffering a large amount of data in memory
    response.read_body do |data|
      fh.write data
    end
    fh.rewind
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
