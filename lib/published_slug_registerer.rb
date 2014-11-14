require "gds_api/publishing_api"
require 'gds_api/panopticon'

# Registers slugs for published editions with other apps
# Currently, this is content store and panopticon (and panopticon in turn
# updates search).
class PublishedSlugRegisterer

  attr_reader :logger

  def initialize(logger, slugs)
    @logger = logger
    @slugs = slugs.sort.uniq
  end

  def run
    @success_slugs = []
    @not_found_slugs = []
    @errored_slugs = []
    @count = 0

    logger.info "Registering #{@slugs.count} slugs"

    @slugs.each do |slug|
      register(slug)
    end

    log_result
  end

private

  def log_result
    if @success_slugs.present?
      logger.info "\nSuccessfully registered the following #{@success_slugs.count} slugs:"
      @success_slugs.each do |slug|
        logger.info slug
      end
    end

    if @not_found_slugs.present?
      logger.info "\nThe following #{@not_found_slugs.count} slugs weren't found:"
      @not_found_slugs.each do |slug|
        logger.info slug
      end
    end

    if @errored_slugs.present?
      logger.info "\nUnable to register the following #{@errored_slugs.count} slugs:"
      @errored_slugs.each do |slug|
        logger.info slug
      end
    end

    logger.info "\nRegistration complete: processed #{@success_slugs.count} slugs successfully, #{@not_found_slugs.count} slugs not found, #{@errored_slugs.count} slugs had errors"
  end

  def published_edition(slug)
    Edition.find_and_identify(slug, nil)
  end

  def register(slug)
    @count += 1
    logger.info "Registering #{slug} [#{@count}/#{@slugs.count}]"
    edition = published_edition(slug)
    if edition
      if register_with_panopticon(edition) && register_with_publishing_api(edition)
        @success_slugs << slug
      else
        @errored_slugs << slug
      end
    else
      @not_found_slugs << slug
      logger.error "No published edition found with slug #{slug}"
    end
  end

  def register_with_publishing_api(edition)
    presenter = PublishedEditionPresenter.new(edition)
    document_for_publishing_api = presenter.render_for_publishing_api(republish: true)
    base_path = document_for_publishing_api[:base_path]

    publishing_api.put_content_item(base_path, document_for_publishing_api)
    true
  end

  def publishing_api
    @publishing_api ||= GdsApi::PublishingApi.new(Plek.find("publishing-api"))
  end

  def register_with_panopticon(edition)
    retry_count = 0
    begin
      edition.register_with_panopticon
      return true
    rescue Mongoid::Errors::DocumentNotFound
      # This happens if an Edition doesn't have a corresponding Artefact
      logger.warn "Missing Artefact for #{edition.class.name} #{edition.slug}"
    rescue Edition::ResurrectionError
      logger.error "Attempted to register archived edition '#{edition.slug}'"
    rescue Timeout::Error, GdsApi::TimedOutException
      if retry_count < 3
        retry_count += 1
        logger.warn "Encountered timeout for '#{edition.slug}', retrying (max 3 retries)"
        retry
      else
        logger.error "Encountered 4 timeouts for '#{edition.slug}', skipping"
      end
    rescue GdsApi::HTTPErrorResponse => e
      logger.error %{Failed to register '#{edition.slug}' with error #{e.code}: "#{e.error_details}"}
    end
    false
  end
end
