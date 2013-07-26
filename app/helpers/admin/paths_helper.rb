module Admin::PathsHelper
  def publication_front_end_path(publication)
    raise "Publication without slug: #{publication.id}" if publication.slug.blank?
    app = publication.rendering_app rescue nil # This isn't defined in the govuk_content_models
    app = "private-frontend" if app.nil? 
    "#{Plek.current.find(app)}/#{publication.slug}"
  end

  def preview_edition_path(edition)
    publication_front_end_path(edition) + "?edition=#{edition.version_number}&cache=#{Time.zone.now().to_i}"
  end

  def start_work_path(edition)
    send("start_work_admin_edition_path", edition)
  end

  def path_for_edition(edition)
    send("admin_edition_path", edition)
  end

  def edit_edition_path(edition)
    "/admin/editions/#{edition.to_param}"
  end

  def view_edition_path(edition)
    "/admin?with=#{edition.id}"
  end

protected
  def path_from_edition_class(edition)
    edition.format.underscore.pluralize
  end
end
