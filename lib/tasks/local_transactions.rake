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

end