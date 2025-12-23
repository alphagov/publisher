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

  def preview_edition_guide_part_path(edition, chapter)
    path = edition_front_end_path(edition) << "/#{chapter.slug}"

    if should_have_auth_bypass_id?(edition)
      path << "?token=#{jwt_token(edition)}"
    end

    path
  end

  def preview_homepage_path(edition)
    path = "#{preview_url(edition)}" # rubocop:disable Style/RedundantInterpolation

    if should_have_auth_bypass_id?(edition)
      path << "?token=#{jwt_token(edition)}"
    end

    path
  end

  def view_homepage_path
    gov_uk_root_url
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

  def gov_uk_root_url
    Plek.website_root
  end

private

  def should_have_auth_bypass_id?(edition)
    %w[published archived].exclude?(edition.state)
  end
end
