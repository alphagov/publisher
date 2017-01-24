class MainstreamSlugUpdater

  def initialize(old_slug, new_slug, logger = nil)
    @old_slug = old_slug.sub(/^\//, '')
    @new_slug = new_slug.sub(/^\//, '')
    @logger = logger || Logger.new(nil)
  end

  def update
    update_slug_on_all_editions
    update_artefact_slug
    reregister_slug
  end

  def published_edition
    @published_edition ||= editions.find { |e| e.published? }
  end

private
  attr_reader(
    :old_slug,
    :new_slug,
    :logger
  )

  def user
    @user ||= User.find_or_create_by(name: "2nd Line Support")
  end

  def editions
    @editions ||= Edition.where(slug: old_slug).to_a
  end

  def artefact
    @artefact ||= Artefact.find_by_slug(old_slug)
  end

  def update_slug_on_all_editions
    logger.info "Updating the slug on all Editions"
    editions.each do |e|
      e.slug = new_slug
      e.save(validate: false)
    end
  end

  def update_artefact_slug
    logger.info "Updating the slug on the Artefact"
    artefact.slug = new_slug
    artefact.save_as(user, validate: false)
  end

  def reregister_slug
    logger.info "Re-registering with rummager / publishing-api"
    published_edition.notify_publishing_platform_services
  end
end
