require 'rest_client'

class LocalInteractionImporter < LocalAuthorityDataImporter
  INTERACTIONS_LIST_URL = "http://local.direct.gov.uk/Data/local_authority_service_details.csv"

  def self.fetch_data
    fetch_http_to_file(INTERACTIONS_LIST_URL)
  end

  def initialize(fh)
    super
    @authorities = {}
  end

  private

  def process_row(row)
    return if row['SNAC'].blank?
    authority = authority(row)

    existing_interactions = authority.interactions_for(row['LGSL'], row['LGIL'])
    if existing_interactions.count == 0
      authority.local_interactions.create!(
        lgsl_code: row['LGSL'],
        lgil_code: row['LGIL'],
        url: row['Service URL'].strip
      )
    elsif existing_interactions.count == 1
      i = existing_interactions.first
      i.update_attributes!(url: row['Service URL'].strip)
    else
      raise "Error: duplicate definitions already exist for interaction [lgsl=#{row['LGSL']}, lgil=#{row['LGIL']}] for authority '#{row['SNAC']}'"
    end
  end

  def authority(row)
    @authorities[row['SNAC']] ||= create_or_update_authority(row)
  end

  def create_or_update_authority(row)
    if la = LocalAuthority.find_by_snac(row['SNAC'])
      Rails.logger.info("Updating authority '%s' (snac %s)" % [row['Authority Name'], row['SNAC']])
      la.update_attributes!(
        name: row['Authority Name'],
        local_directgov_id: row['LAid'],
        tier: identify_tier(row['SNAC'])
      )
      la
    else
      Rails.logger.info("New authority '%s' (snac %s)" % [row['Authority Name'], row['SNAC']])
      LocalAuthority.create!(
        name: row['Authority Name'],
        snac: row['SNAC'],
        local_directgov_id: row['LAid'],
        tier: identify_tier(row['SNAC'])
      )
    end
  end

  def identify_tier(snac)
    mapit_type_to_tier(authority_type_from_mapit(snac))
  end

  def authority_type_from_mapit(snac)
    url = "#{MAPIT_BASE_URL}area/#{snac}"
    Rails.logger.debug("Finding authority type from mapit, url #{url}")
    raw_response = RestClient.get(url)
    response = JSON.parse(raw_response.body)
    response['type']
  rescue RestClient::ResourceNotFound
    nil
  end

  def mapit_type_to_tier(mapit_type)
    case mapit_type
    when 'DIS' then 'district'
    when 'CTY' then 'county'
    when 'LBO','MTD','UTA' then 'unitary'
    else
      'county'
    end
  end
end
