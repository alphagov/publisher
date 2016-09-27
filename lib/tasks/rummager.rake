require "published_slug_registerer"

namespace :rummager do
  desc "Indexes all editions in Rummager"
  task index_all: :environment do
    task_logger.info "Sending published editions to rummager..."
    slugs = Edition.published.map(&:slug)
    PublishedSlugRegisterer.new(task_logger, slugs).do_rummager
  end

  def task_logger
    @_task_logger ||= GdsApi::Base.logger = Logger.new(STDERR).tap { |l| l.level = Logger::INFO }
  end
end
