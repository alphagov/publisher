require "published_slug_registerer"

namespace :reregister do

  desc "Re-register all published editions"
  task :all => :environment do
    logger.info "Re-registering all published editions..."
    slugs = Edition.published.map(&:slug)
    PublishedSlugRegisterer.new(logger, slugs).run
  end

  desc "Re-register published editions for slugs from stdin"
  task :slugs_from_stdin => :environment do
    logger.info "Re-registering published editions for slugs from stdin..."
    slugs = []
    while line = STDIN.gets
      slugs << line.chomp
    end
    PublishedSlugRegisterer.new(logger, slugs).run
  end

  desc "Re-register published editions tagged to a topic, read from the TOPIC environment variable"
  task :by_topic => :environment do
    topic = ENV.fetch('TOPIC')
    logger.info "Re-registering all published editions tagged to topic #{topic}..."
    slugs = Artefact.where(
      tags: {"tag_id" => topic, "tag_type" => "specialist_sector"},
      owning_app: "publisher",
    ).map(&:slug)
    PublishedSlugRegisterer.new(logger, slugs).run
  end

  desc "Re-register published editions tagged to a browse page, read from the BROWSE_PAGE environment variable"
  task :by_mainstream_browse => :environment do
    browse_page = ENV.fetch('BROWSE_PAGE')
    logger.info "Re-registering all published editions tagged to mainstream browse page #{browse_page}..."
    slugs = Artefact.where(
      tags: {"tag_id" => browse_page, "tag_type" => "section"},
      owning_app: "publisher",
    ).map(&:slug)
    PublishedSlugRegisterer.new(logger, slugs).run
  end

  desc "Re-register published editions tagged to an organisation, read from the ORGANISATION environment variable"
  task :by_organisation => :environment do
    organisation = ENV.fetch('ORGANISATION')
    logger.info "Re-registering all published editions tagged to organisation #{organisation}..."
    slugs = Artefact.where(
      tags: {"tag_id" => organisation, "tag_type" => "organisation"},
      owning_app: "publisher",
    ).map(&:slug)
    PublishedSlugRegisterer.new(logger, slugs).run
  end

  def logger
    @_logger ||= GdsApi::Base.logger = Logger.new(STDERR).tap { |l| l.level = Logger::INFO }
  end
end
