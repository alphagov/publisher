class LocalTransactionsImporter
  attr_accessor :io, :seen_authorities

  def initialize(io)
    self.io = io
    self.seen_authorities = []
  end

  def handle_services(source, row)
    source_authority_cache = {}
    authority_cache = {}
    lgsl_cache = {}
    begin
      unless lgsl = lgsl_cache[row['LGSL'].to_s]
        lgsl = source.lgsls.find_or_create_by(code: row['LGSL'].to_s)
        lgsl_cache[row['LGSL'].to_s] = lgsl
      end

      unless authority = authority_cache[row['SNAC']]
        authority = lgsl.authorities.find_or_initialize_by(snac: row['SNAC'])
        authority_cache[row['SNAC']] = authority
      end

      unless source_authority = source_authority_cache[row['SNAC']]
        source_authority = ::Authority.where(snac: row['SNAC']).first
        source_authority_cache[row['SNAC']] = source_authority
      end

      authority.name = source_authority.name unless source_authority.nil?
      authority.lgils.build(code: row['LGIL'].to_s, url: row['Service URL'])
      lgsl.save!
    rescue => e
      puts "Failure at row:"
      puts " * #{row.inspect}"
      puts " * #{e.message}"
    end
  end

  def ensure_authority(row)
    authority = Authority.find_or_initialize_by(snac: row['SNAC'])
    authority.name = row['Authority Name']
    authority.agency_id = row['LAid']
    authority.save!
  end

  def run
    source = LocalTransactionsSource.create

    CSV.new(io, headers: true).each do |row|
      begin
        unless seen_authorities.include?(row['SNAC'])
          ensure_authority(row)
          seen_authorities << row['SNAC']
        end

        handle_services(source, row)
      rescue => e
        puts "Failure at row:"
        puts " * #{row.inspect}"
        puts " * #{e.message}"
      end
    end
  end
end