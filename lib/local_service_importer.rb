require 'csv'

class LocalServiceImporter
  def self.update
    fh = fetch_data
    begin
      new(fh).run
    ensure
      fh.close
    end
  end

  def self.fetch_data
    File.open('data/local_services.csv', 'r:Windows-1252:UTF-8')
  end

  def initialize(fh)
    @filehandle = fh
  end

  def run
    CSV.new(@filehandle, headers: true).each do |row|
      begin
        process_row(row)
      rescue => e
        Rails.logger.error "Error #{e.class} processing row in #{self.class}\n#{e.backtrace.join("\n")}"
        GovukError.notify(e, extra: { row: row })
      end
    end
  end

private

  def process_row(row)
    existing_service = LocalService.find_by_lgsl_code(row['LGSL'])

    if existing_service
      Rails.logger.info("Update service %s: '%s' provided by %s" % [row['LGSL'], row['Description'], providing_tier(row)])
      existing_service.update_attributes!(
        description: row['Description'],
        providing_tier: providing_tier(row)
      )
    else
      Rails.logger.info("Import service %s: '%s' provided by %s" % [row['LGSL'], row['Description'], providing_tier(row)])
      LocalService.create!(
        lgsl_code: row['LGSL'],
        description: row['Description'],
        providing_tier: providing_tier(row),
      )
    end
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
end
