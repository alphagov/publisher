require "published_slug_registerer"

namespace :panopticon do
  desc "Send all published editions to Panopticon"
  task reregister_all: [:environment] do
    task_logger.info "Re-registering all published editions..."
    slugs = Edition.published.map(&:slug)
    PublishedSlugRegisterer.new(task_logger, slugs).do_panopticon
  end

  def task_logger
    @_task_logger ||= GdsApi::Base.logger = Logger.new(STDERR).tap { |l| l.level = Logger::INFO }
  end
end
