namespace :panopticon do
  desc "Register content with panopticon"
  task :register => :environment do
    require 'gds_api/panopticon'
    logger = GdsApi::Base.logger = Logger.new(STDERR).tap { |l| l.level = Logger::INFO }
    logger.info "Registering with panopticon..."

    Edition.published.each do |edition|
      begin
        edition.register_with_panopticon
      rescue Mongoid::Errors::DocumentNotFound
        # This happens if an Edition doesn't have a corresponding Artefact
        logger.warn "Missing Artefact for #{edition.class.name} #{edition.slug}"
      end
    end
  end
end
