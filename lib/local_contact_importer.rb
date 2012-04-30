require 'csv'

class LocalContactImporter
  CONTACTS_LIST_URL = "http://local.direct.gov.uk/Data/local_authority_contact_details.csv"

  def self.fetch_data
    tmp = Tempfile.new(['local_contacts', '.csv'])

    uri = URI.parse(CONTACTS_LIST_URL)
    response = Net::HTTP.get_response(uri)

    # This will read the data in a chuncked fasion, and
    # will avoid buffering a large amount of data in memory
    response.read_body do |data|
      tmp.write data
    end
    tmp.rewind
    tmp
  end

  def self.update
    io = fetch_data
    begin
      new(io).run
    ensure
      io.close
    end
  end

  def initialize(io)
    @io = io
  end

  def run
    CSV.new(@io, headers: true).each do |row|
      next if row['SNAC Code'].blank?
      authority = LocalAuthority.where(:snac => row['SNAC Code']).first
      next unless authority
      authority.name = decode_broken_entities( row['Name'] )
      authority.contact_address = parse_address(row)
      authority.contact_phone = decode_broken_entities( row['Telephone Number 1'] )
      authority.contact_url = row['Contact page URL']
      authority.contact_email = row['Main Contact Email']
      authority.save!
    end
  end

  private

  def parse_address(row)
    [row['Address Line 1'], row['Address Line 2'], row['Town'], row['City'], row['County'], row['Postcode']].reject(&:blank?)
  end

  # The CSV contains some broken HTML entities (e.g. &#40) note the missing ;
  # This will decode any printable ascii characters, and leave any others unchanged.
  def decode_broken_entities(string)
    # Catch any non-broken entities
    string = CGI.unescape_html(string)
    # Handle the broken entities (ones with a missing ;)
    string.gsub(/&\#([0-9]+)/) do
      n = $1.to_i
      if n > 31 and n < 127
        n.chr(string.encoding)
      else
        "&##{$1}"
      end
    end
  end
end
