module Admin::PathsHelper
  def publication_front_end_path(publication)
    raise "Publication without slug: #{publication.id}" if publication.slug.blank?
    "#{Plek.current.find("publication-preview")}/#{publication.slug}"
  end

  def preview_edition_path(edition)
    publication_front_end_path(edition) + "?edition=#{edition.version_number}&cache=#{Time.now().to_i}"
  end

  def start_work_path(edition)
    send("start_work_admin_edition_path", edition)
  end

  def path_for_edition(edition)
    send("admin_edition_path", edition)
  end

  def edit_edition_path(edition)
    "/admin/#{path_from_edition_class(edition)}/#{edition.to_param}"
  end

protected
  def path_from_edition_class(edition)
    edition.format.underscore.pluralize
  end
end