module PathsHelper
  def edition_front_end_path(edition)
    "#{preview_url(edition)}/#{edition.slug}"
  end

  def fact_check_edition_path(edition)
    if edition.fact_check_id
      token = jwt_token(sub: edition.fact_check_id)
      url = preview_edition_path(edition)
      url << "&token=#{token}"
      url
    else
      preview_edition_path(edition)
    end
  end

  def preview_edition_path(edition, cache_bust = Time.zone.now.to_i)
    path = edition_front_end_path(edition) + "?"
    path << "edition=#{edition.version_number}&" unless edition.migrated?
    path << "cache=#{cache_bust}"
    path
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
end
