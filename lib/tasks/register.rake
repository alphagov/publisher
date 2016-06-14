require "published_slug_registerer"

namespace :reregister do

  desc "Send all published editions to Panopticon"
  task :all => :environment do
    task_logger.info "Re-registering all published editions..."
    slugs = Edition.published.map(&:slug)
    PublishedSlugRegisterer.new(task_logger, slugs).run
  end

  def task_logger
    @_task_logger ||= GdsApi::Base.logger = Logger.new(STDERR).tap { |l| l.level = Logger::INFO }
  end
end
