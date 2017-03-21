module PathsHelper
  def edition_front_end_path(edition)
    "#{preview_url(edition)}/#{edition.slug}"
  end

  def preview_edition_path(edition, cache_bust = Time.zone.now.to_i)
    params = []
    params << "edition=#{edition.version_number}" unless edition.migrated?
    params << "cache=#{cache_bust}"

    if should_have_fact_check_id?(edition)
      token = jwt_token(sub: edition.fact_check_id)
      params << "token=#{token}"
    end

    edition_front_end_path(edition) + "?" + params.join("&")
  end

  def start_work_path(edition)
    send("start_work_edition_path", edition)
  end

  def path_for_edition(edition)
    send("edition_path", edition)
  end

  def edit_edition_path(edition)
    "/editions/#{edition.to_param}"
  end

protected

  def jwt_token(sub:)
    JWT.encode({ 'sub' => sub }, jwt_auth_secret, 'HS256')
  end

  def jwt_auth_secret
    Rails.application.config.jwt_auth_secret
  end

  def path_from_edition_class(edition)
    edition.format.underscore.pluralize
  end

  def preview_url(edition)
    if edition.migrated?
      Plek.current.find("draft-origin")
    else
      Plek.current.find("private-frontend")
    end
  end

private

  def should_have_fact_check_id?(edition)
    edition.migrated? &&
    %w(published archived).exclude?(edition.state) &&
    edition.fact_check_id
  end
end
