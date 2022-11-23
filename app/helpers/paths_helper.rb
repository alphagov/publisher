module PathsHelper
  def edition_front_end_path(edition)
    "#{preview_url(edition)}/#{edition.slug}"
  end

  def preview_edition_path(edition)
    path = edition_front_end_path(edition)

    if should_have_auth_bypass_id?(edition)
      path << "?token=#{jwt_token(edition)}"
    end

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

  def jwt_token(edition)
    payload = {
      "sub" => edition.auth_bypass_id,
      "content_id" => edition.content_id,
      "iat" => Time.zone.now.to_i,
      "exp" => 1.month.from_now.to_i,
    }
    JWT.encode(payload, jwt_auth_secret, "HS256")
  end

  def jwt_auth_secret
    Rails.application.config.jwt_auth_secret
  end

  def path_from_edition_class(edition)
    edition.format.underscore.pluralize
  end

  def preview_url(_edition)
    Plek.external_url_for("draft-origin")
  end

private

  def should_have_auth_bypass_id?(edition)
    %w[published archived].exclude?(edition.state)
  end
end
