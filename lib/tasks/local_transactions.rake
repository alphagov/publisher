namespace :local_transactions do

  desc "Import local transactions data from CSV file <SOURCE> (e.g. SOURCE=local_transactions.csv)"
  task :import => :environment do
    unless ENV['SOURCE']
      puts "Please specify the source file in $SOURCE"
      puts "You can download the 'Local Authority Service Details' from http://local.direct.gov.uk/Data/"
      exit(1)
    end

    require 'logger'
    logger = Logger.new(STDERR)
    logger.info "Importing local service definitions..."
    LocalServiceImporter.new(File.open('data/local_services.csv', 'r:Windows-1252:UTF-8'), logger: logger).run

    logger.info "Importing local interaction links..."
    LocalInteractionImporter.new(File.open(ENV['SOURCE'], 'r:Windows-1252:UTF-8'), logger: logger).run
  end

  desc "Download the latest service list CSV from Local Directgov and import"
  task :fetch => :environment do
    SERVICE_LIST_URL = "http://local.direct.gov.uk/Data/local_authority_service_details.csv"

    @local_file_name = ENV['FILENAME'] || Rails.root.join('data', 'local_interactions.csv')

    require 'logger'
    logger = Logger.new(STDERR)

    logger.info "Downloading #{SERVICE_LIST_URL}..."
    uri = URI.parse(SERVICE_LIST_URL)
    content = Net::HTTP.get(uri.host, uri.path).force_encoding('UTF-8')

    logger.info "Saving content to #{@local_file_name}..."
    File.open(@local_file_name, 'w') {|f| f.write(content) }

    ENV['SOURCE'] = @local_file_name.to_s

    logger.info "Invoking import task..."
    Rake::Task["local_transactions:import"].execute
  end

end