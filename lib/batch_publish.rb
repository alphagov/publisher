class BatchPublish
  def initialize(edition_identifiers, email)
    @edition_identifiers = edition_identifiers
    @email = email
  end

  def call
    editions = []
    @edition_identifiers.each do |identifier|
      edition = Edition.where(
          slug: identifier.fetch(:slug),
          version_number: identifier.fetch(:edition)
      ).first
      if edition.nil?
        Rails.logger.error "Edition couldn't be found for #{identifier}"
      elsif ["ready", "published"].exclude?(edition.state)
        Rails.logger.error "Edition #{identifier} isn't 'published' or 'ready'. It's #{edition.state}"
      else
        editions << edition
      end
    end

    editions.each do |edition|
      published = user.progress(edition, { request_type: "publish", comment: "" })
      if published
        Rails.logger.info("Published #{edition.slug} #{edition.version_number}")
      else
        Rails.logger.info("Skipped #{edition.slug} #{edition.version_number}")
      end
    end
  end

  def user
    @user ||= User.where(email: @email).first
  end
end