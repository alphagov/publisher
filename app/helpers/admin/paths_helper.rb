module Admin::PathsHelper
  def publication_front_end_path(publication)
    raise "Publication without slug: #{publication.id}" if publication.slug.blank?
    "#{Plek.current.find("publication-preview")}/#{publication.slug}"
  end

  def preview_edition_path(edition)
    publication_front_end_path(edition.container) + "?edition=#{edition.version_number}&cache=#{Time.now().to_i}"
  end

  def admin_editions_path(publication)
    send("admin_#{publication.class.to_s.underscore}_editions_path", publication)
  end

  def start_work_path(edition)
    publication = edition.container
    send("start_work_admin_#{edition.class.to_s.underscore}_path", publication, edition)
  end

  def path_for_edition(edition)
    send("admin_#{edition.container.class.to_s.underscore}_edition_path", edition.container, edition)
  end
end