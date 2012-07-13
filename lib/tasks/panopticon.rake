namespace :panopticon do
  desc "Register content with panopticon"
  task :register => :environment do
    require 'gds_api/panopticon'
    logger = GdsApi::Base.logger = Logger.new(STDERR).tap { |l| l.level = Logger::INFO }
    logger.info "Registering with panopticon..."

    Edition.published.each do |edition|
      edition.register_with_panopticon
    end
  end
end
