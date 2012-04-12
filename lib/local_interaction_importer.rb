require 'csv'

class LocalInteractionImporter
  def initialize(io, options = {})
    @io = io
    @authorities = {}
    @logger = options[:logger] || NullLogger.instance
  end

  def authority(row)
    @authorities[row['SNAC']] ||= LocalAuthority.find_by_snac(row['SNAC']) || create_authority(row)
  end

  def run
    CSV.new(@io, headers: true).each do |row|
      next if row['SNAC'].blank?
      authority = authority(row)

      existing_interactions = authority.interactions_for(row['LGSL'], row['LGIL'])
      if existing_interactions.count == 0
        authority.local_interactions.create!(
          lgsl_code: row['LGSL'],
          lgil_code: row['LGIL'],
          url: row['Service URL']
        )
      elsif existing_interactions.count == 1
        i = existing_interactions.first
        i.update_attributes!(url: row['Service URL'])
      else
        raise "Error: duplicate definitions already exist for interaction [lgsl=#{row['LGSL']}, lgil=#{row['LGIL']}] for authority '#{row['SNAC']}'"
      end
    end
  end

private

  def create_authority(row)
    @logger.info("New authority '%s' (snac %s)" % [row['Authority Name'], row['SNAC']])
    authority_tier = identify_tier(row['SNAC'])
    LocalAuthority.create!(
      name: row['Authority Name'],
      snac: row['SNAC'],
      local_directgov_id: row['LAid'],
      tier: authority_tier
    )
  end

  def identify_tier(snac)
    mapit_type_to_tier(authority_type_from_mapit(snac))
  end

  def authority_type_from_mapit(snac)
    url = "http://mapit.mysociety.org/area/#{snac}"
    @logger.debug("Finding authority type from mapit, url #{url}")
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