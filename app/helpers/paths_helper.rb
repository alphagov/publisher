module PathsHelper
  def edition_front_end_path(edition)
    "#{preview_url(edition)}/#{edition.slug}"
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
  def path_from_edition_class(edition)
    edition.format.underscore.pluralize
  end

  def preview_url(edition)
    if edition.migrated?
      Plek.current.find("draft-frontend")
    else
      Plek.current.find("private-frontend")
    end
  end
end
