require 'csv'

class LocalServiceImporter
  def initialize(io, options = {})
    @io = io
    @logger = options[:logger] || NullLogger.instance
  end
  
  def providing_tier(row)
    value = row['Providing Tier']
    case value
    when "county/unitary", "district/unitary" then
      value.split('/')
    when "all" then
      %w{district unitary county}
    else
      raise "Illegal 'Providing Tier' '#{value}'"
    end
  end
  
  def run
    CSV.new(@io, headers: true).each do |row|
      next if LocalService.find_by_lgsl_code(row['LGSL'])
      @logger.info("Import service %s: '%s' provided by %s" % [row['LGSL'], row['Description'], providing_tier(row)])
      LocalService.create!(
        lgsl_code: row['LGSL'], 
        description: row['Description'],
        providing_tier: providing_tier(row),
        )
    end
  end  
end