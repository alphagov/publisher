class BatchPublish
  def initialize(edition_identifiers, email)
    @edition_identifiers = edition_identifiers
    @email = email
  end

  def call
    editions = @edition_identifiers.map do |identifier|
      edition = Edition.where(
          slug: identifier.fetch(:slug),
          version_number: identifier.fetch(:edition)
      ).first
      unless edition
        raise "Edition couldn't be found for #{identifier}"
      end
      unless edition.ready? || edition.published?
        raise "Edition #{identifier} isn't 'published' or 'ready'. It's #{edition.state}"
      end
      edition
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