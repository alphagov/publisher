class PublishedEditionPresenter
  def initialize(edition)
    @edition = edition
  end

  def render_for_publishing_api
    {
      title: @edition.title,
      base_path: base_path,
      description: @edition.overview,
      format: "placeholder",
      need_ids: [],
      public_updated_at: @edition.updated_at,
      publishing_app: "publisher",
      rendering_app: "frontend",
      routes: [
        {path: base_path, type: "exact"}
      ],
      redirects: [],
      update_type: "major",
      details: {
        change_note: "",
        tags: {
          browse_pages: @edition.browse_pages,
          topics: [],
        }
      }
    }
  end

private

  def base_path
    "/#{@edition.slug}"
  end
end
