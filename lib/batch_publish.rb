class BatchPublish
  MAX_RETRIES = 5

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
      retry_count = 0
      begin
        edition.reload
        published = user.progress(edition, { request_type: "publish", comment: "" })

        if published
          Rails.logger.info("Published #{edition.slug} #{edition.version_number}")
        elsif edition.published?
          # If it's already published, try registering with panopticon again
          edition.register_with_panopticon
          Rails.logger.info("Registered #{edition.slug} #{edition.version_number} with Panopticon")
        else
          Rails.logger.info("Skipped #{edition.slug} #{edition.version_number}")
        end
      rescue StandardError => e
        if retry_count < MAX_RETRIES
          Rails.logger.error("Retrying to publish #{edition.slug} #{edition.version_number}. Error: #{e.message}")
          retry_count += 1
          retry
        else
          Rails.logger.error("Failed to publish #{edition.slug} #{edition.version_number}. Error: #{e.message}")
        end
      end
    end
  end

  def user
    @user ||= User.where(email: @email).first
  end
end
